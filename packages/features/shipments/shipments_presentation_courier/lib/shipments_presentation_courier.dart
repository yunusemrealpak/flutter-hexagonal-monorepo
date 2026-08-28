/// The shipments UI as a courier sees it: a stop list and a scan flow.
///
/// One half of scenario 7. `shipments_presentation_dispatcher` is the other,
/// and the two consume the same `shipments_api` — the same `ShipmentsFacade`,
/// the same `ShipmentSummary`, the same state machine — while showing
/// completely different screens. That is what makes a driving adapter
/// replaceable rather than merely swappable in principle.
///
/// This package holds no adapter and no use case. It depends on contracts
/// only, so what actually answers `ShipmentsFacade` is decided by whichever
/// app composed it: the real coordinator in `app_courier`, a fake in
/// `app_harness`.
library;

export 'src/courier_manifest_controller.dart';
export 'src/courier_manifest_screen.dart';
export 'src/courier_manifest_state.dart';
export 'src/shipments_courier_routes.dart';
export 'src/shipments_courier_strings.dart';
