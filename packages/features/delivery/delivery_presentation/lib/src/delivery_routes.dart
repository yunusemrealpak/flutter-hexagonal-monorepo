import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to an app.
///
/// It carries no router library. An app collects a module from every
/// presentation package it includes and builds its router from the union,
/// which is why `app_courier` and `app_dispatcher` can include different
/// features and neither feature has to know which app it ended up in.
///
/// `requiredPermission` is a string here rather than a `Permission`, and that
/// is `core_navigation`'s doing: it may depend on `core_kernel` only, so it
/// cannot name identity's enum. The app's router resolves the string through
/// `PermissionChecker` when it builds the guard.
///
/// **The route guard and the button guard are both scenario 6, and they are
/// not the same check.** The route keeps somebody out of the screen; the
/// button keeps them from recording a hand-over once they are on it. A courier
/// whose grant is revoked mid-visit is already past the router.
final class DeliveryRoutes implements RouteModule {
  /// Creates the module.
  const DeliveryRoutes();

  @override
  String get moduleName => 'delivery';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'delivery.proof',
      path: '/stops/:shipmentId/proof',
      requiredPermission: 'completeDelivery',
    ),
  ];
}
