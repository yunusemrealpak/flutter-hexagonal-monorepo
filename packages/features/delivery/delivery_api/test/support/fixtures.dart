import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Fixtures for this package's own tests.
///
/// They live here rather than in `delivery_testing`, because that package
/// depends on this one and the arrow cannot run both ways. What
/// `delivery_testing` publishes is for *other* packages' tests; a contract
/// package's own suite builds its own values.
///
/// Nothing here calls `DateTime.now()` — rule A1. A proof whose timestamp
/// depends on when the suite ran is a proof no assertion can pin down.
abstract final class Fixtures {
  /// The instant every fixture measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// A shipment, by identifier.
  static ShipmentId shipment([String raw = 'SHP-1']) =>
      unwrap(ShipmentId.parse(raw));

  /// A courier, by identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      unwrap(ActorId.parse(raw));

  /// An attempt identifier.
  static DeliveryAttemptId attemptId([String raw = 'attempt-1']) =>
      unwrap(DeliveryAttemptId.parse(raw));

  /// A proof reference.
  static ProofReference reference([String raw = 'proof-1']) =>
      unwrap(ProofReference.parse(raw));

  /// Somebody at the door.
  static Recipient recipient([String name = 'A. Yilmaz']) =>
      unwrap(Recipient.named(name));

  /// A signature.
  static SignatureCapture signature() =>
      unwrap(SignatureCapture.of(bytes: const [1, 2, 3], capturedAt: noon));

  /// A photograph.
  static PhotoEvidence photo({List<int> bytes = const [4, 5, 6]}) =>
      unwrap(PhotoEvidence.of(bytes: bytes, capturedAt: noon));

  /// A scan.
  static ScanEvidence scan([String symbol = '1234567890128']) =>
      unwrap(ScanEvidence.of(symbol: symbol, scannedAt: noon));

  /// A proof carrying whatever it is given.
  static ProofOfDelivery proof({
    SignatureCapture? signature,
    PhotoEvidence? photo,
    ScanEvidence? scan,
  }) => ProofOfDelivery.captured(
    recipient: recipient(),
    capturedAt: noon,
    signature: signature,
    photo: photo,
    scan: scan,
  );

  /// An attempt in progress.
  static DeliveryAttempt attempt({
    DeliveryGrade grade = DeliveryGrade.standard,
  }) => DeliveryAttempt.started(
    id: attemptId(),
    shipment: shipment(),
    courier: courier(),
    startedAt: noon,
    grade: grade,
  );

  /// Unwraps a `Result`, failing loudly rather than returning a default.
  static T unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
