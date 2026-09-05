import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// Enforces the size a photograph has to fit into, and refuses when it does
/// not.
///
/// **It does not re-encode, and the reason is worth reading rather than
/// working around.** The cheapest place to make a photograph small is the
/// camera: `MediaCapture.capturePhoto` in `platform/media_capture` takes
/// `maxWidthPixels` and `quality`, and downscaling at capture costs nothing
/// because the pixels were never allocated. Re-encoding afterwards means
/// decoding a JPEG, resampling it and encoding it again — an image library,
/// on the main isolate of a device that is already holding a day's queue.
///
/// So this adapter is the *decision* half of the port and not the arithmetic
/// half. It answers "does this fit", it returns the photograph untouched when
/// it does, and it says `MediaTooLarge` when it does not — which sends the
/// courier back to the camera rather than leaving an entry stuck in an outbox
/// on a device with no signal.
///
/// The port stays a port for exactly that reason: the decision belongs to
/// `delivery`, has to be testable without a device, and is the thing that
/// changes when an operation moves to a different transport. An app that
/// acquires an image library binds a different adapter here and nothing else
/// in the feature moves.
final class BudgetMediaCompressor implements MediaCompressorPort {
  /// Creates the adapter.
  const BudgetMediaCompressor();

  @override
  Future<Result<PhotoEvidence, DeliveryFailure>> compress(
    PhotoEvidence photo, {
    required int limitBytes,
  }) async {
    if (photo.byteCount <= limitBytes) return Success(photo);

    return Failed(
      MediaTooLarge(bytes: photo.byteCount, limit: limitBytes),
    );
  }
}
