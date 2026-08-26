import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'delivery_failure.dart';

/// A photograph of the hand-over, or of where the parcel was left.
///
/// Like `SignatureCapture`, it defines no `==`: comparing two photographs
/// byte-by-byte is expensive and nothing in the domain asks the question.
///
/// It carries no size limit of its own. What a photograph is allowed to weigh
/// depends on what will carry it — a queue on a device, a request over a
/// mobile connection — and both of those are technology facts. The limit lives
/// with `MediaCompressorPort`, where the caller can say what it is.
@immutable
final class PhotoEvidence {
  const PhotoEvidence._({
    required this.bytes,
    required this.capturedAt,
    required this.mimeType,
  });

  /// Reads a photograph, refusing an empty one.
  static Result<PhotoEvidence, DeliveryFailure> of({
    required List<int> bytes,
    required DateTime capturedAt,
    String mimeType = 'image/jpeg',
  }) {
    if (bytes.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'photo', reason: 'is empty'),
      );
    }
    if (!mimeType.startsWith('image/')) {
      return Failed(
        MalformedDeliveryValue(
          field: 'photo.mimeType',
          reason: '$mimeType is not an image',
        ),
      );
    }
    return Success(
      PhotoEvidence._(
        bytes: List<int>.unmodifiable(bytes),
        capturedAt: capturedAt.toUtc(),
        mimeType: mimeType,
      ),
    );
  }

  /// The image, as bytes.
  final List<int> bytes;

  /// When the shutter went, in UTC.
  final DateTime capturedAt;

  /// What kind of image it is.
  final String mimeType;

  /// How much it weighs.
  int get byteCount => bytes.length;

  @override
  String toString() => 'PhotoEvidence($mimeType, ${bytes.length} bytes)';
}
