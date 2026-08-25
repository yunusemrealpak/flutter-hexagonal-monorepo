/// The shipments UI as an operations desk sees it: a filterable board, a
/// selection, and permission-gated bulk actions.
///
/// The other half of scenario 7. `shipments_presentation_courier` consumes the
/// same `shipments_api` — the same `ShipmentsFacade`, the same
/// `ShipmentSummary`, the same state machine — and shows a completely
/// different screen. That is what makes a driving adapter replaceable rather
/// than merely swappable in principle.
///
/// It is also where scenario 6 lives. `DispatcherBoardController` takes
/// identity's `PermissionChecker` and asks *may this actor bulk-assign?* The
/// answer is a `bool`. This package does not know that identity has roles,
/// that a role carries a permission set, or that any of it is decided by a
/// class called `Actor` — and if identity replaced all of that tomorrow,
/// nothing here would change.
library;

export 'src/dispatcher_board_controller.dart';
export 'src/dispatcher_board_screen.dart';
export 'src/dispatcher_board_state.dart';
export 'src/shipments_dispatcher_routes.dart';
