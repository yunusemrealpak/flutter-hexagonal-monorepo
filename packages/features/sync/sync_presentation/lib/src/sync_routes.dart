import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers to an app.
///
/// It carries no router library. An app collects a module from every
/// presentation package it includes and builds its router from the union,
/// which is why `app_courier` and `app_dispatcher` can include different
/// features and neither feature has to know which app it ended up in.
///
/// `requiredPermission` is a string here rather than a `Permission`, and that
/// is `core_navigation`'s doing: it may depend on `core_kernel` only, so it
/// cannot name identity's enum. The app's router resolves the string through
/// `PermissionChecker` when it builds the guard.
///
/// One route rather than two. The badge is a widget an app embeds in whatever
/// chrome it already has; a route for it would be a screen showing one line.
final class SyncRoutes implements RouteModule {
  /// Creates the module.
  const SyncRoutes();

  @override
  String get moduleName => 'sync';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'sync.review',
      path: '/sync/review',
      // Resolving stuck work means deciding what happens to a delivery or a
      // payment somebody else recorded, which is a supervisor's job rather
      // than a courier's.
      requiredPermission: 'manageSettings',
    ),
  ];
}
