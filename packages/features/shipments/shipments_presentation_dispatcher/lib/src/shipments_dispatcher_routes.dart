import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers.
///
/// The app collects a module from every presentation package it includes and
/// builds its router from the union, which is why this type carries no router
/// library: `app_courier` and `app_dispatcher` include different features and
/// neither feature has to know which app it ended up in.
final class ShipmentsDispatcherRoutes implements RouteModule {
  /// Creates the module.
  const ShipmentsDispatcherRoutes();

  @override
  String get moduleName => 'shipments_dispatcher';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'shipments_dispatcher.home',
      path: '/shipments_dispatcher',
    ),
  ];
}
