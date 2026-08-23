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
/// The contract is one method on purpose. Every extra capture mode — video,
/// gallery selection, multiple images — is a permission story, a size story
/// and a compression story of its own, and the product needs exactly one of
/// them today. A contract that offered five would be five things to fake, five
/// things to test, and four that nothing calls.
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
}
