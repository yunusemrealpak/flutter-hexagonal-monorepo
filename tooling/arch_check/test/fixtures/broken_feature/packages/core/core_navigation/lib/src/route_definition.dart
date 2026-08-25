/// One destination a feature offers.
final class RouteDefinition {
  /// Describes a destination.
  const RouteDefinition({required this.name, required this.path});

  /// A stable identifier.
  final String name;

  /// The path pattern.
  final String path;
}
