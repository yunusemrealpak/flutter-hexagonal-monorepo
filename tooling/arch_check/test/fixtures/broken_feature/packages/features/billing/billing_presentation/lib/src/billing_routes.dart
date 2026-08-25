import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers. This part is correct.
final class BillingRoutes implements RouteModule {
  /// Creates it.
  const BillingRoutes();

  @override
  String get moduleName => 'billing';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'billing.home', path: '/billing'),
  ];
}
