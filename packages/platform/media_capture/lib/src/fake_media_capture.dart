import 'package:core_kernel/core_kernel.dart';
import 'capture_failure.dart';
import 'captured_media.dart';
import 'media_capture.dart';

/// A [MediaCapture] that answers from the test instead of from a camera.
///
/// A delivery flow that ends in photo evidence is one of the longest paths in
/// the product, and without this every test of it would need a device. Queue
/// what the camera "returned" — including a cancellation, which is the branch
/// most easily left untested — and assert on what the flow did with it.
final class FakeMediaCapture implements MediaCapture {
  final List<Result<CapturedMedia, CaptureFailure>> _queued = [];

  /// Every `(maxWidthPixels, quality)` pair a call asked for, oldest first.
  final List<(int, int)> requestedSettings = [];

  /// Makes the next [capturePhoto] answer with [result].
  void queue(Result<CapturedMedia, CaptureFailure> result) =>
      _queued.add(result);

  @override
  Future<Result<CapturedMedia, CaptureFailure>> capturePhoto({
    int maxWidthPixels = 1600,
    int quality = 80,
  }) async {
    requestedSettings.add((maxWidthPixels, quality));
    if (_queued.isEmpty) {
      // Failing rather than throwing keeps the fake honest to the contract it
      // implements, and the detail names what the test forgot.
      return const Failed(
        CaptureUnavailable(detail: 'FakeMediaCapture had nothing queued'),
      );
    }
    return _queued.removeAt(0);
  }
}
