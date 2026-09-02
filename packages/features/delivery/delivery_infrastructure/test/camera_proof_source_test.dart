@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_capture/media_capture.dart';

/// Turning a camera into proof of delivery.
///
/// The two halves that are easy to get wrong are both about a photograph the
/// application never saw returned: Android takes it in another activity and is
/// entitled to kill the activity that asked. Recovering it is the point of this
/// class; recovering it *onto the right parcel* is the part a naive recovery
/// gets wrong, and the one that matters — a photograph attached to somebody
/// else's delivery is a false proof.
void main() {
  final noon = DateTime.utc(2026, 3, 14, 12);

  late FakeMediaCapture camera;
  late InMemoryKeyValueStore store;
  late RecordingLogger logger;
  late CameraProofSource source;

  CapturedMedia media(String path) => CapturedMedia(
    path: path,
    mimeType: 'image/jpeg',
    byteSize: 32,
    capturedAt: noon,
  );

  setUp(() {
    camera = FakeMediaCapture();
    store = InMemoryKeyValueStore();
    logger = RecordingLogger();
    source = CameraProofSource(
      capture: camera,
      compressor: const BudgetMediaCompressor(),
      store: store,
      logger: logger,
    );
  });

  PhotoEvidence unwrap(Result<PhotoEvidence, CaptureRefusal> result) =>
      result.fold(
        (photo) => photo,
        (refusal) => throw StateError('expected a photo, got $refusal'),
      );

  CaptureRefusal refusalOf(Result<PhotoEvidence, CaptureRefusal> result) =>
      result.fold(
        (photo) => throw StateError('expected a refusal, got a photo'),
        (refusal) => refusal,
      );

  group('taking one', () {
    test('reads the file the camera produced', () async {
      camera
        ..queue(Success(media('/tmp/proof.jpg')))
        ..bytes['/tmp/proof.jpg'] = List<int>.filled(32, 9);

      final photo = unwrap(await source.photograph('SHP-1'));

      expect(photo.byteCount, 32);
      expect(photo.capturedAt, noon);
      expect(photo.mimeType, 'image/jpeg');
    });

    test('a courier who backs out is told apart from the rest', () async {
      camera.queue(const Failed(CaptureCancelled()));

      // Not an error, and never something to report — but not a null either.
      // Answering nothing is what made a blocked camera and a changed mind the
      // same event, which is the whole reason this type exists.
      expect(
        refusalOf(await source.photograph('SHP-1')),
        isA<CaptureDeclined>(),
      );
    });

    test('a camera refused once can be asked for again', () async {
      camera.queue(const Failed(CapturePermissionDenied()));

      // Pressing the button shows the prompt again, so the button stays and
      // the settings page is not offered.
      expect(
        refusalOf(await source.photograph('SHP-1')),
        isA<CaptureNotAllowed>(),
      );
    });

    test('a camera blocked in the settings says so', () async {
      camera.queue(const Failed(CapturePermissionBlocked()));

      // The case with a way out of it. Collapsed into the others, the only
      // failure a courier could act on became the one nothing acted on.
      expect(
        refusalOf(await source.photograph('SHP-1')),
        isA<CaptureBlockedInSettings>(),
      );
    });

    test('reports a file the operating system already reclaimed', () async {
      // Queued with no bytes registered: the path is real and the file is not.
      camera.queue(Success(media('/tmp/gone.jpg')));

      expect(
        refusalOf(await source.photograph('SHP-1')),
        isA<EvidenceUnusable>().having(
          (unusable) => unusable.failure,
          'failure',
          isA<DeliveryUnavailable>(),
        ),
      );
    });

    test('refuses a photograph over the budget', () async {
      camera
        ..queue(Success(media('/tmp/huge.jpg')))
        ..bytes['/tmp/huge.jpg'] = List<int>.filled(4 * 1024 * 1024, 1);

      expect(
        refusalOf(await source.photograph('SHP-1')),
        isA<EvidenceUnusable>().having(
          (unusable) => unusable.failure,
          'failure',
          isA<MediaTooLarge>(),
        ),
      );
    });
  });

  group('recovering one the operating system interrupted', () {
    test('uses it instead of opening the camera again', () async {
      // The state after a kill: the marker says which parcel was being proved,
      // and the platform is holding the file.
      await source.photograph('SHP-1');
      camera
        ..lostCapture = media('/tmp/lost.jpg')
        ..bytes['/tmp/lost.jpg'] = List<int>.filled(16, 4);

      final photo = unwrap(await source.photograph('SHP-1'));

      expect(photo.byteCount, 16);
      // The camera was opened once, for the capture that was interrupted.
      // Asking a courier to photograph a parcel they have already photographed
      // is the whole thing `getLostData` exists to avoid.
      expect(camera.requestedSettings, hasLength(1));
    });

    test('will not attach it to a different parcel', () async {
      await source.photograph('SHP-1');
      camera
        ..lostCapture = media('/tmp/lost.jpg')
        ..bytes['/tmp/lost.jpg'] = List<int>.filled(16, 4)
        ..queue(Success(media('/tmp/fresh.jpg')))
        ..bytes['/tmp/fresh.jpg'] = List<int>.filled(8, 2);

      final photo = unwrap(await source.photograph('SHP-2'));

      // A photograph of one parcel attached to another is a false proof of
      // delivery, and nothing downstream could ever tell. The marker is what
      // makes the recovery attributable.
      expect(photo.byteCount, 8);
      expect(camera.requestedSettings, hasLength(2));
    });

    test('ignores one nobody was waiting for', () async {
      camera
        ..lostCapture = media('/tmp/lost.jpg')
        ..bytes['/tmp/lost.jpg'] = List<int>.filled(16, 4)
        ..queue(Success(media('/tmp/fresh.jpg')))
        ..bytes['/tmp/fresh.jpg'] = List<int>.filled(8, 2);

      final photo = unwrap(await source.photograph('SHP-1'));

      // No marker, so nothing claims the file. Using it would attach a
      // photograph from an unknown parcel to this one.
      expect(photo.byteCount, 8);
    });

    test('is offered once, not on every visit', () async {
      await source.photograph('SHP-1');
      camera
        ..lostCapture = media('/tmp/lost.jpg')
        ..bytes['/tmp/lost.jpg'] = List<int>.filled(16, 4);
      await source.photograph('SHP-1');

      camera
        ..queue(Success(media('/tmp/fresh.jpg')))
        ..bytes['/tmp/fresh.jpg'] = List<int>.filled(8, 2);
      final photo = unwrap(await source.photograph('SHP-1'));

      // The platform hands a lost capture over once and the marker is cleared
      // with it, so a courier taking a second photograph of the same parcel
      // gets the camera rather than the first photograph again.
      expect(photo.byteCount, 8);
    });
  });

  group('the marker', () {
    test('is written before the camera opens', () async {
      // The kill happens inside capturePhoto, so a marker written afterwards
      // is a marker that is never written on the one path that needs it.
      camera.queue(const Failed(CaptureUnavailable(detail: 'killed')));

      await source.photograph('SHP-1');

      expect(store.entries.values, contains('SHP-1'));
    });

    test('does not stop a capture when it cannot be written', () async {
      store.failNextWith(const StoreOutOfSpace());
      camera
        ..queue(Success(media('/tmp/proof.jpg')))
        ..bytes['/tmp/proof.jpg'] = List<int>.filled(32, 9);

      final photo = unwrap(await source.photograph('SHP-1'));

      // Losing the marker costs one unattributable recovery. Refusing the
      // capture costs the courier their evidence at a door they are standing
      // at now.
      expect(photo.byteCount, 32);
      expect(logger.records, isNotEmpty);
    });
  });
}
