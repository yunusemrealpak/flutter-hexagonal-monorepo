import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// The only route in phase 6 that a courier's app has no business including at
/// all. It is guarded with `viewReports` all the same, because "we will not
/// put it in that app" is a decision somebody can reverse in a pull request,
/// and the guard is what makes reversing it safe.
final class ReportingRoutes implements RouteModule {
  /// Creates the module.
  const ReportingRoutes();

  @override
  String get moduleName => 'reporting';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'reports.board',
      path: '/reports',
      requiredPermission: 'viewReports',
    ),
  ];
}
