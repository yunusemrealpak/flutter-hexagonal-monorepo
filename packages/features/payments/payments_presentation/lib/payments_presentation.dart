/// The payments UI: the screen a courier takes money on.
///
/// **Scenario 6 for the third time.** `CollectionController.canCollect` asks
/// `identity_api`'s `PermissionChecker` whether the signed-in actor holds
/// `Permission.collectPayment`, and learns nothing else.
/// `shipments_presentation_dispatcher` asks before bulk assignment,
/// `delivery_presentation` before recording a hand-over, and none of the three
/// knows anything about roles or grants. `PaymentsRoutes` guards the two
/// destinations with two different permissions, because taking money and
/// giving it back are not the same authority.
///
/// **The amount is read, never typed.** It comes from `PaymentStatus`, so a
/// courier cannot collect a different number from the one the operation is
/// owed. A text field here would be exactly where that difference got in, and
/// afterwards it would be indistinguishable from a typing mistake.
///
/// **Minor units become a decimal in one place**, `CollectionScreen.render`,
/// using the currency's own scale. Everywhere else in the feature an amount is
/// an integer and a currency — which is what keeps a day's total exact.
///
/// **There is no clock here**, and there cannot be: section 2 gives this row
/// `core_kernel`, `core_navigation`, contracts and Flutter, not `core_ports`.
/// Nothing on this screen needs one — the instants a collection carries are
/// stamped by the use case, which has a `Clock`.
///
/// This package holds no adapter and no use case. What answers `PaymentsFacade`
/// is decided by whichever app composed it.
library;

export 'src/collection_controller.dart';
export 'src/collection_screen.dart';
export 'src/collection_state.dart';
export 'src/payments_routes.dart';
export 'src/payments_strings.dart';
