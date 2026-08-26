import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to an app.
///
/// **Two destinations, two permissions**, and they are not the same authority.
/// Reporting an exception is something a courier does at a door; working down
/// the board is something an operation does. A single permission would mean
/// either couriers reading every incident in the fleet, or dispatchers unable
/// to record what a phone call just told them.
///
/// `requiredPermission` is a string rather than a `Permission`, and that is
/// `core_navigation`'s doing: it may depend on `core_kernel` only, so it
/// cannot name identity's enum. The app's router resolves the string through
/// `PermissionChecker` when it builds the guard.
final class IncidentsRoutes implements RouteModule {
  /// Creates the module.
  const IncidentsRoutes();

  @override
  String get moduleName => 'incidents';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'incidents.report',
      path: '/incidents/report',
      requiredPermission: 'reportIncident',
    ),
    RouteDefinition(
      name: 'incidents.board',
      path: '/incidents',
      requiredPermission: 'viewReports',
    ),
  ];
}
