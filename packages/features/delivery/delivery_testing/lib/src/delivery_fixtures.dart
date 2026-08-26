import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Fixtures for delivery, shared by this package's contract kit and by every
/// package that consumes it.
///
/// Everything here is deterministic and nothing calls `DateTime.now()` — rule
/// A1. Evidence whose timestamp depends on when the suite ran is evidence no
/// assertion can pin down.
///
/// The bytes are three of them. A fixture that carried a real JPEG would make
/// every failure message unreadable and would tempt somebody to assert on its
/// contents; what the domain cares about is that there *are* bytes, which is
/// exactly what `SignatureCapture.of` refuses to do without.
abstract final class DeliveryFixtures {
  /// The instant every fixture measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// A shipment, by identifier.
  static ShipmentId shipment([String raw = 'SHP-1']) =>
      _unwrap(ShipmentId.parse(raw));

  /// A courier, by identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      _unwrap(ActorId.parse(raw));

  /// An attempt identifier.
  static DeliveryAttemptId attemptId([String raw = 'attempt-1']) =>
      _unwrap(DeliveryAttemptId.parse(raw));

  /// A proof reference.
  static ProofReference reference([String raw = 'proof-1']) =>
      _unwrap(ProofReference.parse(raw));

  /// Somebody at the door.
  static Recipient recipient({
    String name = 'A. Yilmaz',
    String relationship = 'self',
  }) => _unwrap(Recipient.named(name, relationship: relationship));

  /// A signature.
  static SignatureCapture signature({List<int> bytes = const [1, 2, 3]}) =>
      _unwrap(SignatureCapture.of(bytes: bytes, capturedAt: noon));

  /// A photograph.
  static PhotoEvidence photo({List<int> bytes = const [4, 5, 6]}) =>
      _unwrap(PhotoEvidence.of(bytes: bytes, capturedAt: noon));

  /// A scan.
  static ScanEvidence scan([String symbol = '1234567890128']) =>
      _unwrap(ScanEvidence.of(symbol: symbol, scannedAt: noon));

  /// A proof carrying whatever it is given, and a signature by default.
  ///
  /// The default is one piece of evidence rather than none, because a proof
  /// with none is refused by every grade and a fixture that has to be repaired
  /// before it can be used is a fixture nobody uses.
  static ProofOfDelivery proof({
    SignatureCapture? signature,
    PhotoEvidence? photo,
    ScanEvidence? scan,
  }) => ProofOfDelivery.captured(
    recipient: recipient(),
    capturedAt: noon,
    signature:
        signature ??
        (photo == null && scan == null ? DeliveryFixtures.signature() : null),
    photo: photo,
    scan: scan,
  );

  /// A proof that satisfies `DeliveryGrade.highValue`.
  static ProofOfDelivery fullProof() =>
      proof(signature: signature(), photo: photo());

  /// An attempt in progress.
  static DeliveryAttempt attempt({
    String id = 'attempt-1',
    DeliveryGrade grade = DeliveryGrade.standard,
    String shipmentId = 'SHP-1',
  }) => DeliveryAttempt.started(
    id: attemptId(id),
    shipment: shipment(shipmentId),
    courier: courier(),
    startedAt: noon,
    grade: grade,
  );

  /// An attempt that was completed with [proof] under [reference].
  static DeliveryAttempt completed({
    String id = 'attempt-1',
    String reference = 'proof-1',
    ProofOfDelivery? proof,
  }) => _unwrap(
    attempt(id: id).completeWith(
      proof: proof ?? DeliveryFixtures.proof(),
      reference: DeliveryFixtures.reference(reference),
      at: noon,
    ),
  );

  /// An attempt that ended without a hand-over.
  static DeliveryAttempt failed({
    String id = 'attempt-1',
    NonDeliveryReason reason = const NonDeliveryReason.recipientAbsent(),
  }) => _unwrap(attempt(id: id).failWith(reason: reason, at: noon));

  static T _unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
