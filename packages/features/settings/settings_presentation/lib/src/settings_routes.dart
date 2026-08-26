import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// One route, and no `requiredPermission`. Every signed-in actor may change
/// their own language and palette — a permission on this route would be
/// asking whether somebody is allowed to be spoken to in their own language.
///
/// `requiresSession` is left at its default of true, and that is not a
/// formality: preferences are stored per actor, so a screen reached without a
/// session would have nobody's settings to show.
final class SettingsRoutes implements RouteModule {
  /// Creates the module.
  const SettingsRoutes();

  @override
  String get moduleName => 'settings';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'settings.home', path: '/settings'),
  ];
}
