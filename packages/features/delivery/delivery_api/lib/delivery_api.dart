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

export 'src/entities/delivery_attempt.dart';
export 'src/events/delivery_completed.dart';
export 'src/failures/capture_refusal.dart';
export 'src/failures/delivery_failure.dart';
export 'src/ports/driven/delivery_gateway.dart';
export 'src/ports/driven/geo_fence_port.dart';
export 'src/ports/driven/media_compressor_port.dart';
export 'src/ports/driven/proof_store_port.dart';
export 'src/ports/driving/delivery_execution.dart';
export 'src/ports/driving/delivery_history.dart';
export 'src/ports/driving/delivery_settlement.dart';
export 'src/values/attempt_outcome.dart';
export 'src/values/courier_reference.dart';
export 'src/values/delivery_attempt_id.dart';
export 'src/values/delivery_grade.dart';
export 'src/values/evidence_kind.dart';
export 'src/values/geo_fence_verdict.dart';
export 'src/values/non_delivery_reason.dart';
export 'src/values/photo_evidence.dart';
export 'src/values/proof_of_delivery.dart';
export 'src/values/proof_policy.dart';
export 'src/values/proof_reference.dart';
export 'src/values/recipient.dart';
export 'src/values/scan_evidence.dart';
export 'src/values/shipment_reference.dart';
export 'src/values/signature_capture.dart';
