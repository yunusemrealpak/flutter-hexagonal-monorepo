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
/// **Two destinations, one screen.** The difference between them is whose
/// route is on it, and that difference is a permission rather than a layout:
/// seeing your own afternoon comes with being a courier, and opening somebody
/// else's is the thing a dispatcher can do that a courier cannot. Declaring
/// them as one route with an optional segment would have made the guard the
/// same for both and quietly handed every courier the whole operation.
final class RoutingRoutes implements RouteModule {
  /// Creates the module.
  const RoutingRoutes();

  @override
  String get moduleName => 'routing';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'routing.myRoute',
      path: '/route',
      requiredPermission: 'viewAssignedShipments',
    ),
    RouteDefinition(
      name: 'routing.courierRoute',
      path: '/couriers/:courierId/route',
      requiredPermission: 'viewAllShipments',
    ),
  ];
}
