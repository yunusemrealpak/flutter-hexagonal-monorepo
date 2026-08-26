import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers.
///
/// The app collects a module from every presentation package it includes and
/// builds its router from the union, which is why this type carries no router
/// library: `app_courier` and `app_dispatcher` include different features and
/// neither feature has to know which app it ended up in.
final class PaymentsRoutes implements RouteModule {
  /// Creates the module.
  const PaymentsRoutes();

  @override
  String get moduleName => 'payments';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'payments.home', path: '/payments'),
  ];
}
