/// Turns a snake_case feature name into the other spellings the templates
/// need.
///
/// Nothing clever: the workspace's naming convention is snake_case
/// directories, snake_case files and PascalCase types, so the only conversion
/// anyone needs is between those two.
final class Naming {
  /// Creates the spellings for one feature, optionally qualified by the
  /// variant of a presentation package.
  Naming(this.feature, {this.variant = ''});

  /// The feature's snake_case name, e.g. `vehicle_inventory`.
  final String feature;

  /// The presentation variant, e.g. `courier`. Empty for every other role.
  final String variant;

  /// `vehicle_inventory` becomes `VehicleInventory`; a variant is appended,
  /// so `vehicle_inventory` plus `courier` becomes `VehicleInventoryCourier`.
  String get pascal =>
      _pascal('${feature}_$variant'.replaceAll(RegExp(r'_$'), ''));

  /// The snake_case prefix for a file name, variant included.
  String get snake => variant.isEmpty ? feature : '${feature}_$variant';

  /// The feature's PascalCase name without the variant.
  String get featurePascal => _pascal(feature);

  static String _pascal(String snake) => snake
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();

  /// Whether [name] is a usable feature name: lower snake_case, starting with
  /// a letter. Dart package names allow nothing else, and a name that pub
  /// rejects is a name that produces an unresolvable workspace.
  static bool isValidFeatureName(String name) =>
      RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$').hasMatch(name);
}
