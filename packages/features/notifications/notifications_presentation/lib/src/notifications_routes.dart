import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// One route and no `requiredPermission`: an inbox holds what the operation
/// chose to tell this person, so being the person is the whole authority.
/// `requiresSession` stays at its default of true, because an inbox reached
/// without a session would have nobody's alerts to show.
final class NotificationsRoutes implements RouteModule {
  /// Creates the module.
  const NotificationsRoutes();

  @override
  String get moduleName => 'notifications';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'notifications.inbox', path: '/inbox'),
  ];
}
