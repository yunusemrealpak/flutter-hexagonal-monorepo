import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'capture_failure.dart';
import 'captured_media.dart';
import 'media_capture.dart';

/// What a file is called when the platform does not say.
const _fallbackMimeType = 'image/jpeg';

/// The [MediaCapture] the shipped applications run on.
///
/// Like `GeolocatorLocationSource`, it takes [PermissionRequester] through its
/// constructor rather than letting the plugin handle permission: one mechanism
/// for the whole app, and no `platform/*` -> `platform/*` edge to
/// `device_permissions`.
///
/// The [Clock] is here because the platform does not timestamp a capture and
/// something has to. Reading the system clock would make every assertion about
/// `capturedAt` approximate; injected, it is a value the test states. That is
/// rule A1, and this is the second place in the workspace where obeying it
/// costs a constructor parameter.
final class ImagePickerMediaCapture implements MediaCapture {
  /// Captures through the given platform implementation, asking the given
  /// requester for access and stamping the result from the given clock.
  const ImagePickerMediaCapture(this._platform, this._permissions, this._clock);

  final ImagePickerPlatform _platform;
  final PermissionRequester _permissions;
  final Clock _clock;

  @override
  Future<Result<CapturedMedia, CaptureFailure>> capturePhoto({
    int maxWidthPixels = 1600,
    int quality = 80,
  }) async {
    final blocked = await _blockedByPermission();
    if (blocked != null) {
      return Failed(blocked);
    }
    try {
      final file = await _platform.getImageFromSource(
        source: ImageSource.camera,
        options: ImagePickerOptions(
          maxWidth: maxWidthPixels.toDouble(),
          imageQuality: quality,
          // preferredCameraDevice is left at its default, which is the rear
          // camera — the one pointed at a parcel.
        ),
      );
      if (file == null) {
        // The user backed out. Not an error, and its own case so that a caller
        // can tell "nothing happened" from "something broke".
        return const Failed(CaptureCancelled());
      }
      return Success(
        CapturedMedia(
          path: file.path,
          mimeType: file.mimeType ?? _fallbackMimeType,
          byteSize: await file.length(),
          capturedAt: _clock.now(),
        ),
      );
    } on Object catch (error) {
      return Failed(CaptureUnavailable(detail: error.toString()));
    }
  }

  Future<CaptureFailure?> _blockedByPermission() async {
    var state = await _permissions.status(DevicePermission.camera);
    if (state == PermissionState.notDetermined) {
      state = await _permissions.request(DevicePermission.camera);
    }
    return switch (state) {
      PermissionState.granted => null,
      PermissionState.denied ||
      PermissionState.notDetermined => const CapturePermissionDenied(),
      PermissionState.permanentlyDenied ||
      PermissionState.restricted => const CapturePermissionBlocked(),
    };
  }
}
