import 'package:core_kernel/core_kernel.dart';
import 'capture_failure.dart';
import 'captured_media.dart';

/// Takes a photo, without throwing.
///
/// A technology contract, declared here for the same reason `HttpTransport`
/// and `LocationSource` are declared in their own platform packages: nothing
/// in the product asks for "a photo". `delivery` asks for proof that a parcel
/// reached a consignee, and its `_infrastructure` answers that using this.
///
/// **One capture *mode* on purpose**, which is not the same as one method.
/// Every extra mode — video, gallery selection, multiple images — is a
/// permission story, a size story and a compression story of its own, and the
/// product needs exactly one of them today. The other two methods below are
/// that same mode's other halves: getting the photograph back when the
/// operating system interrupted it, and reading the file it left behind.
abstract interface class MediaCapture {
  /// Opens the camera and returns what the user took.
  ///
  /// [maxWidthPixels] and [quality] are downscaling instructions handed to the
  /// platform, not post-processing done here. A courier's phone takes 12
  /// megapixel photos; the evidence needs to be legible, not archival, and the
  /// difference is what a shift's worth of uploads costs on a metered link.
  Future<Result<CapturedMedia, CaptureFailure>> capturePhoto({
    int maxWidthPixels,
    int quality,
  });

  /// The capture the operating system killed this application in the middle
  /// of, or null when there was not one.
  ///
  /// **Android takes the photograph in another activity**, and is entitled to
  /// reclaim the memory of the one that asked for it while the camera is in
  /// front. The photograph is taken and saved; the `Future` from
  /// [capturePhoto] never completes because the isolate that was waiting on it
  /// is gone. This call is the only route back to that file, and this
  /// product's payload is proof-of-delivery photographs.
  ///
  /// **Reading it consumes it.** The platform hands the record over once, so a
  /// caller that asked twice would get nothing the second time — and a fake
  /// that kept answering would let a test pass against behaviour a device will
  /// not repeat.
  ///
  /// Null rather than a `Result`, for the reason `PushMessagingClient
  /// .launchMessage` gives: a platform that does not implement this, a capture
  /// that was lost with an error, and a launch that interrupted nothing all
  /// mean the same thing to a caller — open the camera.
  Future<CapturedMedia?> recoverLostCapture();

  /// Reads the bytes of a file this contract produced.
  ///
  /// Here rather than at the caller because the package that produced the path
  /// is the one that knows how to read it, and because keeping `dart:io` on
  /// this side of the boundary is what lets everything above be tested without
  /// a filesystem.
  ///
  /// A `Result`, unlike [recoverLostCapture]: `CapturedMedia.path` is
  /// documented as temporary, so a file the operating system has reclaimed is
  /// a case the caller has to be able to see. It shows a courier that the
  /// photograph is gone and offers the camera again.
  Future<Result<List<int>, CaptureFailure>> bytesOf(CapturedMedia media);
}
