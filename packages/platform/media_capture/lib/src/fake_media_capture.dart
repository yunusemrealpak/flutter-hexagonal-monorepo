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

  /// The capture a test says the operating system interrupted.
  ///
  /// Consumed on the first read, because that is what the platform does. A
  /// fake that kept answering would let a test pass against behaviour a device
  /// will not repeat — an application that read it twice would attach the same
  /// recovered photograph to two deliveries.
  CapturedMedia? lostCapture;

  /// The bytes [bytesOf] answers with, keyed by path.
  ///
  /// A map rather than a queue: reading a file is not an event, and a test that
  /// had to queue one read per call would be describing an order that does not
  /// exist.
  final Map<String, List<int>> bytes = {};

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

  @override
  Future<CapturedMedia?> recoverLostCapture() async {
    final lost = lostCapture;
    lostCapture = null;
    return lost;
  }

  @override
  Future<Result<List<int>, CaptureFailure>> bytesOf(CapturedMedia media) async {
    final stored = bytes[media.path];
    if (stored == null) {
      // The file is gone, which is the case `CapturedMedia.path` warns about
      // and the one a caller most often forgets to handle.
      return Failed(
        CaptureUnavailable(detail: 'FakeMediaCapture has no ${media.path}'),
      );
    }
    return Success(stored);
  }
}
