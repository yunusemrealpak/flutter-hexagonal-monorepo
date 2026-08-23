import 'package:core_navigation/src/route_definition.dart';

/// What a presentation package exposes so that an app can mount it.
///
/// Each `_presentation` package provides one module. An app depends on the
/// presentation packages it wants, collects their modules, and builds its
/// router from the union. Adding a screen to a feature therefore changes one
/// package, and adding a feature to an app changes one list.
abstract interface class RouteModule {
  /// A stable name for this module, used in diagnostics when two modules
  /// declare the same route name.
  String get moduleName;

  /// Every destination this module offers.
  List<RouteDefinition> get routes;
}
