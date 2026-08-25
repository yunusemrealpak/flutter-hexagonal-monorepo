/// One entry in a pubspec's `dependencies:` or `dev_dependencies:` block.
///
/// The distinction the checker needs is not the version constraint but where
/// the package comes from: an SDK dependency (`flutter: {sdk: flutter}`) is
/// governed by a different column of the dependency table than a hosted one.
final class Dependency {
  /// Creates a dependency entry as it was written in the pubspec.
  const Dependency({required this.name, this.sdk});

  /// The package name, which is the key of the pubspec entry.
  final String name;

  /// The SDK this dependency is pulled from, when the pubspec entry is a map
  /// with an `sdk:` key. `null` for a hosted, path or git dependency.
  final String? sdk;

  /// Whether the entry names an SDK rather than a hosted package.
  bool get isSdk => sdk != null;

  @override
  String toString() => isSdk ? '$name (sdk: $sdk)' : name;
}
