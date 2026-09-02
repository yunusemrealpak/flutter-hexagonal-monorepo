/// The delivery contract: one visit to one address, what closes it, and what
/// it takes to prove it happened.
///
/// **The rule this package exists to place is `ProofPolicy`.** How much
/// evidence a hand-over needs depends on what the parcel is worth — a
/// signature *and* a photograph for a high-value one, any single piece for the
/// rest — and the specification asks for that rule to live in a policy object
/// inside `_api`. The placement is the lesson: a rule in a use case is a rule
/// one driving adapter obeys, while a rule the entity consults is one that
/// holds for the courier's screen, the dispatcher's correction and the sync
/// drain replaying a queued attempt alike.
///
/// **What crosses to another feature, and what does not.** This package names
/// `ActorId` and `ShipmentId`, and nothing else of theirs. Section 2.1 of
/// docs/DEPENDENCY_RULES.md states the rule the wider literature calls
/// *reference other contexts by identity*: an identifier crosses, a model does
/// not. So there is no `Shipment` here, no `ShipmentSummary` and no
/// `AddressPoint`. What delivery needs to know about a parcel is how much
/// proof it is worth, and that is `DeliveryGrade` — delivery's own word, two
/// cases wide, supplied by whoever already had the manifest row in hand.
///
/// `ShipmentReference` and `CourierReference` are the other half of it. They
/// read a foreign identifier and report a bad one as a *delivery* failure, so
/// that `delivery_infrastructure` — which may see no foreign feature at all —
/// can rebuild the identifiers this contract is expressed in.
///
/// **A failed delivery is not a `DeliveryFailure`.** A courier who found
/// nobody home did their job, so `NonDeliveryReason` sits on the success side
/// of the `Result`. `DeliveryFailure` is for the software: a locked store, an
/// unreachable server, a proof that does not meet the policy.
///
/// **`DeliveryCompleted`** is scenario 2's declaration. `payments_application`
/// subscribes to it through the `DomainEventBus` port and never depends on
/// `delivery_application`; the two share this file and a bus.
///
/// **The driving ports, drawn where a port stops being answerable.**
/// `DeliveryExecution` is arriving at a door and is the only one that needs a
/// `GeoFencePort` — this device's position — so only a courier's app composes
/// it. `DeliverySettlement` closes an attempt and `DeliveryHistory` reads one
/// back; both are answered from a store, a queue and a server, so a desk
/// composes both and can correct a record without claiming to be at the
/// address. They were one `DeliveryFacade` until phase 8; the reasoning is in
/// docs/ARCHITECTURE.md, scenario 5.
///
/// **The driven ports.** `DeliveryGateway`, `ProofStorePort`,
/// `MediaCompressorPort`, `GeoFencePort`, answered by
/// `delivery_infrastructure`.
library;

export 'src/attempt_outcome.dart';
export 'src/capture_refusal.dart';
export 'src/courier_reference.dart';
export 'src/delivery_attempt.dart';
export 'src/delivery_attempt_id.dart';
export 'src/delivery_completed.dart';
export 'src/delivery_execution.dart';
export 'src/delivery_failure.dart';
export 'src/delivery_gateway.dart';
export 'src/delivery_grade.dart';
export 'src/delivery_history.dart';
export 'src/delivery_settlement.dart';
export 'src/evidence_kind.dart';
export 'src/geo_fence_port.dart';
export 'src/geo_fence_verdict.dart';
export 'src/media_compressor_port.dart';
export 'src/non_delivery_reason.dart';
export 'src/photo_evidence.dart';
export 'src/proof_of_delivery.dart';
export 'src/proof_policy.dart';
export 'src/proof_reference.dart';
export 'src/proof_store_port.dart';
export 'src/recipient.dart';
export 'src/scan_evidence.dart';
export 'src/shipment_reference.dart';
export 'src/signature_capture.dart';
