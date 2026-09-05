import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/delivery_failure.dart';

/// A signature, as it came off the glass.
///
/// **No `==`, and that is deliberate.** Two signatures are never "the same
/// signature" in any sense the domain uses, and structural equality over a
/// bitmap means comparing every byte on every comparison — inside a `freezed`
/// union's generated `==`, inside a `Set`, inside a widget's `didUpdateWidget`.
/// Identity equality is both cheaper and more honest.
///
/// The bytes are held rather than a file path. A path is a promise about a
/// filesystem that an `_api` package cannot make: the same proof is captured
/// on a phone, stored encrypted on that phone by one adapter and posted to a
/// server by another, and only the adapters know which of those has a path.
@immutable
final class SignatureCapture {
  const SignatureCapture._({required this.bytes, required this.capturedAt});

  /// Reads a signature, refusing an empty one.
  ///
  /// An empty capture is what a screen produces when somebody taps *done*
  /// without drawing, and accepting it would put a proof in the record that
  /// proves nothing.
  static Result<SignatureCapture, DeliveryFailure> of({
    required List<int> bytes,
    required DateTime capturedAt,
  }) {
    if (bytes.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'signature', reason: 'is empty'),
      );
    }
    return Success(
      SignatureCapture._(
        bytes: List<int>.unmodifiable(bytes),
        capturedAt: capturedAt.toUtc(),
      ),
    );
  }

  /// The image, as bytes.
  final List<int> bytes;

  /// When it was drawn, in UTC.
  final DateTime capturedAt;

  @override
  String toString() => 'SignatureCapture(${bytes.length} bytes)';
}
