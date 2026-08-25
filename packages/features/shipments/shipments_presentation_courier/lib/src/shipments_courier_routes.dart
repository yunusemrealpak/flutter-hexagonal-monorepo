import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers.
///
/// The app collects a module from every presentation package it includes and
/// builds its router from the union, which is why this type carries no router
/// library: `app_courier` and `app_dispatcher` include different features and
/// neither feature has to know which app it ended up in.
final class ShipmentsCourierRoutes implements RouteModule {
  /// Creates the module.
  const ShipmentsCourierRoutes();

  @override
  String get moduleName => 'shipments_courier';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'shipments_courier.home', path: '/shipments_courier'),
  ];
}
