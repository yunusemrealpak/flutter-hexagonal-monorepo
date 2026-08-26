import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// A `MediaCompressorPort` that really shrinks what it is given.
///
/// It truncates, which is not what a real encoder does and is exactly right
/// for a fake: the observable promise of the port is "the result is at or
/// under the limit, or it fails", and truncation keeps that promise in two
/// lines with no image library in the dependency list.
///
/// A photograph already under the limit is returned untouched, byte-identical.
/// That is the behaviour a caller depends on — re-encoding a small image costs
/// quality for nothing — and a fake that rebuilt it anyway would hide a
/// caller that compresses twice.
final class FakeMediaCompressor implements MediaCompressorPort {
  /// The limits this compressor was asked for, in order.
  final List<int> limits = [];

  /// Whether the compressor should refuse rather than shrink.
  ///
  /// The real one refuses when it cannot get under the limit without
  /// destroying the picture, which is the case that leaves an entry stuck in
  /// an outbox on a device with no signal.
  bool refuses = false;

  @override
  Future<Result<PhotoEvidence, DeliveryFailure>> compress(
    PhotoEvidence photo, {
    required int limitBytes,
  }) async {
    limits.add(limitBytes);

    if (refuses) {
      return Failed(
        MediaTooLarge(bytes: photo.byteCount, limit: limitBytes),
      );
    }

    if (photo.byteCount <= limitBytes) return Success(photo);

    return PhotoEvidence.of(
      bytes: photo.bytes.take(limitBytes).toList(),
      capturedAt: photo.capturedAt,
      mimeType: photo.mimeType,
    );
  }
}
