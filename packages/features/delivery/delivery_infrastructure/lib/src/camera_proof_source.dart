import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:media_capture/media_capture.dart';

/// Turns a camera into proof of delivery.
///
/// **This is the row of section 2 that makes the whole arrangement work.** A
/// presentation package may not depend on `platform/*`, so the proof screen
/// takes a callback and the app supplies it; `delivery_application` may not
/// either, so a use case can never see a `CapturedMedia`. A
/// `feature_infrastructure` package may, and it is the only place that can see
/// both `media_capture`'s words and `delivery_api`'s — which is exactly the
/// translation this class performs.
///
/// It answers `Success(null)` for a courier who backs out. `CaptureCancelled`
/// is a failure only in the sense that there is no media; turning it into a
/// `DeliveryFailure` would put a red banner in front of somebody who changed
/// their mind, and `DeliveryFailure` has no case for it because nothing in the
/// domain went wrong.
///
/// ## Recovering a photograph nobody got back
///
/// Android runs the camera in another activity and is entitled to reclaim the
/// one that asked for it. The photograph is taken and saved and the `Future`
/// never completes, so `MediaCapture.recoverLostCapture` is the only route
/// back to the file.
///
/// **Recovering it is not enough; it has to land on the right parcel.** A
/// recovered photograph carries no record of what it was a photograph *of*, so
/// this class writes down which subject it is about before it opens the camera
/// and reads that marker back afterwards. Without it, a courier who lost a
/// capture on one parcel and pressed the camera on the next would attach the
/// first parcel's photograph to the second — a false proof of delivery that
/// nothing downstream could detect.
///
/// The subject is a `String` rather than a `ShipmentId`, for the reason every
/// driven port in this feature gives: section 2 puts no foreign feature on the
/// `feature_infrastructure` row, and an identifier crossing a boundary is a
/// string.
final class CameraProofSource {
  /// Creates the source over the camera it captures with and the store it
  /// remembers the subject in.
  const CameraProofSource({
    required this._capture,
    required this._compressor,
    required this._store,
    required this._logger,
    this.limitBytes = defaultLimitBytes,
    this.maxWidthPixels = 1600,
    this.quality = 80,
  });

  /// How large a photograph is allowed to be, in bytes.
  ///
  /// Two mebibytes, and it is a *budget* rather than a measurement. A courier
  /// takes dozens of these in a shift and drains them over whatever link the
  /// van has; the number is what the operation is willing to spend per door,
  /// and it lives here because nothing else in the workspace had ever named
  /// it — `MediaCompressorPort.compress` takes a limit and every call site was
  /// a test.
  static const int defaultLimitBytes = 2 * 1024 * 1024;

  /// The key the subject of an in-flight capture is remembered under.
  static const String subjectKey = 'delivery.capture.subject';

  final MediaCapture _capture;
  final MediaCompressorPort _compressor;
  final KeyValueStore _store;
  final Logger _logger;

  /// The size a photograph has to fit into.
  final int limitBytes;

  /// How wide the camera is asked to make the image.
  final int maxWidthPixels;

  /// How hard the camera is asked to compress it.
  final int quality;

  /// Photographs [subject], or hands back the photograph of it that was
  /// interrupted.
  ///
  /// `Success(null)` means the courier backed out. A `Failed` is something
  /// that went wrong and that they should be told about — though the screen's
  /// callback cannot carry one today, which is what has to change before a
  /// blocked camera can offer the system settings.
  Future<Result<PhotoEvidence?, DeliveryFailure>> photograph(
    String subject,
  ) async {
    final recovered = await _recoverFor(subject);
    if (recovered != null) {
      return _evidenceFrom(recovered);
    }

    // Written *before* the camera opens, because the kill this exists for
    // happens inside the call below. A marker written afterwards is one that
    // is never written on the only path that needs it.
    await _remember(subject);

    final captured = await _capture.capturePhoto(
      maxWidthPixels: maxWidthPixels,
      quality: quality,
    );

    switch (captured) {
      case Failed(failure: CaptureCancelled()):
        await _forget();
        return const Success(null);
      case Failed(:final failure):
        return Failed(_translate(failure));
      case Success(:final value):
        await _forget();
        return _evidenceFrom(value);
    }
  }

  /// The interrupted photograph of [subject], when there is one and it is
  /// this subject's.
  ///
  /// A lost capture is consumed by reading it, so a mismatch is discarded
  /// rather than left for whoever asks next: the platform will not offer it
  /// again either way, and holding it would mean holding a photograph of an
  /// unknown parcel until something took it by mistake.
  Future<CapturedMedia?> _recoverFor(String subject) async {
    final lost = await _capture.recoverLostCapture();
    if (lost == null) {
      return null;
    }

    final marked = (await _store.read(subjectKey)).fold(
      (value) => value,
      (failure) {
        _logger.warning(
          'the interrupted capture cannot be attributed',
          context: {'failure': '$failure'},
        );
        return null;
      },
    );

    await _forget();
    if (marked == subject) {
      return lost;
    }

    _logger.info(
      'discarding an interrupted capture that belongs to something else',
      context: {'marked': marked ?? 'nothing', 'asked': subject},
    );
    return null;
  }

  /// Reads the file and turns it into evidence the domain accepts.
  Future<Result<PhotoEvidence?, DeliveryFailure>> _evidenceFrom(
    CapturedMedia media,
  ) async {
    final bytes = await _capture.bytesOf(media);
    if (bytes case Failed(:final failure)) {
      return Failed(_translate(failure));
    }

    final read = (bytes as Success<List<int>, CaptureFailure>).value;
    final evidence = PhotoEvidence.of(
      bytes: read,
      capturedAt: media.capturedAt,
      mimeType: media.mimeType,
    );
    if (evidence case Failed(:final failure)) {
      return Failed(failure);
    }

    final photo = (evidence as Success<PhotoEvidence, DeliveryFailure>).value;
    final compressed = await _compressor.compress(
      photo,
      limitBytes: limitBytes,
    );
    return compressed.map<PhotoEvidence?>((value) => value);
  }

  /// Records which subject the capture about to happen is for.
  ///
  /// A write that fails is logged and ignored. Losing the marker costs one
  /// unattributable recovery; refusing the capture costs a courier their
  /// evidence at a door they are standing at now.
  Future<void> _remember(String subject) async {
    final written = await _store.write(subjectKey, subject);
    if (written case Failed(:final failure)) {
      _logger.warning(
        'an interrupted capture would not be attributable',
        context: {'subject': subject, 'failure': '$failure'},
      );
    }
  }

  Future<void> _forget() => _store.delete(subjectKey);

  /// Turns the camera's words into delivery's.
  ///
  /// Every case collapses to `DeliveryUnavailable` with a detail, and that is
  /// deliberate rather than lazy: a caller behaves identically for a refused
  /// permission, a blocked one and a broken platform, because the screen's
  /// callback cannot carry a failure at all. Giving `DeliveryFailure` a case
  /// per camera outcome would put a device's vocabulary into the domain's
  /// sealed union to serve a distinction nothing acts on. The distinction
  /// becomes worth making the day the screen can offer the system settings.
  DeliveryFailure _translate(CaptureFailure failure) => switch (failure) {
    CapturePermissionDenied() => const DeliveryFailure.deliveryUnavailable(
      detail: 'the camera was refused',
    ),
    CapturePermissionBlocked() => const DeliveryFailure.deliveryUnavailable(
      detail: 'the camera is blocked in the system settings',
    ),
    CaptureCancelled() => const DeliveryFailure.deliveryUnavailable(
      detail: 'the camera was dismissed',
    ),
    CaptureUnavailable(:final detail) => DeliveryFailure.deliveryUnavailable(
      detail: detail,
    ),
  };
}
