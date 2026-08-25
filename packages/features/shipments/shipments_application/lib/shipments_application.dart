/// The shipments use cases: pure Dart, and blind to every adapter that answers
/// its ports.
///
/// One class per intention, each with its collaborators in its constructor and
/// nothing else — no locator, no global, no Flutter. Reading a constructor
/// here tells you the complete list of what that use case can touch.
///
/// What is *not* here is as important. The rule about which state may follow
/// which lives in `Shipment`, in `shipments_api`; these use cases call it.
/// A use case orchestrates — read, apply, persist, publish — and an entity
/// decides. When a rule starts appearing in this package, it is a rule that
/// two callers will eventually disagree about.
///
/// `ShipmentsCoordinator` implements `ShipmentsFacade` by delegating to the
/// four use cases. It stays thin on purpose: if it ever grows a decision of
/// its own, that is the signal a use case is missing.
library;

export 'src/advance_shipment.dart';
export 'src/find_shipment.dart';
export 'src/load_manifest.dart';
export 'src/resolve_barcode.dart';
export 'src/shipment_move.dart';
export 'src/shipments_coordinator.dart';
