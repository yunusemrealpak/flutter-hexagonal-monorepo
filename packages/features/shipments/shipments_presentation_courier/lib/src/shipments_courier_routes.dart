import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to the courier app.
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
final class ShipmentsCourierRoutes implements RouteModule {
  /// Creates the module.
  const ShipmentsCourierRoutes();

  @override
  String get moduleName => 'shipments.courier';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'shipments.courier.manifest',
      path: '/stops',
      requiredPermission: 'viewAssignedShipments',
    ),
    RouteDefinition(
      name: 'shipments.courier.scan',
      path: '/stops/scan',
      requiredPermission: 'viewAssignedShipments',
    ),
  ];
}
