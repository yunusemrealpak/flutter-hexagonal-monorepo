import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// One route, no `requiredPermission`. Counting the van you are driving is not
/// an authority somebody grants; it is the job. `requiresSession` stays true,
/// because a count belongs to a courier and there is nobody to count for
/// without one.
final class VehicleInventoryRoutes implements RouteModule {
  /// Creates the module.
  const VehicleInventoryRoutes();

  @override
  String get moduleName => 'vehicle_inventory';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'inventory.count', path: '/vehicle/count'),
  ];
}
