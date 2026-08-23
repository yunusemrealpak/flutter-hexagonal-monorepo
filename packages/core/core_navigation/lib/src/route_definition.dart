/// One destination a feature offers, described so that an app can wire it
/// without knowing what draws it.
///
/// A presentation package declares its definitions; the app collects them from
/// every feature it includes and hands them to whatever router it uses. That
/// is the whole reason this type is pure Dart and free of any router library:
/// `app_courier` and `app_dispatcher` include different feature sets, and
/// neither feature has to know which app it ended up in.
final class RouteDefinition {
  /// Describes a destination.
  const RouteDefinition({
    required this.name,
    required this.path,
    this.requiresSession = true,
    this.requiredPermission,
  });

  /// A stable identifier, unique across the app that assembles it.
  ///
  /// Conventionally `<feature>.<screen>` — `shipments.detail` — so that two
  /// features cannot collide by both wanting `detail`.
  final String name;

  /// The path pattern, with `:` marking a segment the caller supplies.
  ///
  /// For example `/shipments/:shipmentId`.
  final String path;

  /// Whether reaching this destination requires a signed-in actor.
  ///
  /// Defaults to true. In a courier platform an unauthenticated screen is the
  /// exception — sign-in and the legal pages — and a default that has to be
  /// opted out of fails safe when someone forgets to think about it.
  final bool requiresSession;

  /// The permission an actor must hold, or `null` when any signed-in actor may
  /// reach this destination.
  ///
  /// Carried as a plain string rather than a typed permission, because
  /// core_navigation is not allowed to depend on `identity_api` and should not
  /// want to: it states the requirement, and the app's guard resolves it
  /// against the `PermissionChecker` that identity exposes. This is scenario 6
  /// expressed at the route level.
  final String? requiredPermission;

  @override
  String toString() => 'RouteDefinition($name -> $path)';
}
