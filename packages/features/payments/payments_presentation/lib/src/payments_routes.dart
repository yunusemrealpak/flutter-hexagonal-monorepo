import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to an app.
///
/// It carries no router library. An app collects a module from every
/// presentation package it includes and builds its router from the union.
///
/// `requiredPermission` is a string here rather than a `Permission`, and that
/// is `core_navigation`'s doing: it may depend on `core_kernel` only, so it
/// cannot name identity's enum. The app's router resolves the string through
/// `PermissionChecker` when it builds the guard.
///
/// **Two destinations, two permissions.** Taking money and giving it back are
/// not the same authority — an operation that let every courier refund would
/// have no way to tell a mistake from a theft — and `Permission` has had
/// `collectPayment` and `refundPayment` as separate members since phase 4 for
/// exactly this.
final class PaymentsRoutes implements RouteModule {
  /// Creates the module.
  const PaymentsRoutes();

  @override
  String get moduleName => 'payments';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'payments.collect',
      path: '/stops/:shipmentId/collect',
      requiredPermission: 'collectPayment',
    ),
    RouteDefinition(
      name: 'payments.refund',
      path: '/payments/:idempotencyKey/refund',
      requiredPermission: 'refundPayment',
    ),
  ];
}
