import 'route_definition.dart';

/// What a presentation package exposes so an app can mount it.
abstract interface class RouteModule {
  /// A stable name for this module.
  String get moduleName;

  /// Every destination this module offers.
  List<RouteDefinition> get routes;
}
