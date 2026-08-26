import 'package:core_navigation/core_navigation.dart';

/// The destination this package offers to an app.
///
/// One route, parameterised by the thread. No `requiredPermission`: being in a
/// conversation is what entitles somebody to read it, and a permission here
/// would be asking whether a courier may be spoken to.
final class MessagingRoutes implements RouteModule {
  /// Creates the module.
  const MessagingRoutes();

  @override
  String get moduleName => 'messaging';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'messaging.thread', path: '/threads/:threadId'),
  ];
}
