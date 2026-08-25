import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers.
///
/// The only routes in the workspace with `requiresSession: false`, and that is
/// the whole point of the flag: a sign-in screen behind a session guard is a
/// screen nobody can ever reach.
final class IdentityRoutes implements RouteModule {
  /// Creates the module.
  const IdentityRoutes();

  @override
  String get moduleName => 'identity';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'identity.signIn',
      path: '/sign-in',
      requiresSession: false,
    ),
  ];
}
