import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to the dispatcher app.
///
/// The routes carry a `requiredPermission` and the courier's do not carry the
/// same ones, which is the point: two presentation packages over one feature
/// publish different surfaces, and an app's router builds a different guard
/// for each. The string is resolved through `PermissionChecker` when the app
/// composes the router — `core_navigation` may depend on `core_kernel` only,
/// so it cannot name identity's enum.
final class ShipmentsDispatcherRoutes implements RouteModule {
  /// Creates the module.
  const ShipmentsDispatcherRoutes();

  @override
  String get moduleName => 'shipments.dispatcher';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'shipments.dispatcher.board',
      path: '/board',
      requiredPermission: 'viewAllShipments',
    ),
    RouteDefinition(
      name: 'shipments.dispatcher.bulkAssign',
      path: '/board/assign',
      requiredPermission: 'bulkAssignShipments',
    ),
  ];
}
