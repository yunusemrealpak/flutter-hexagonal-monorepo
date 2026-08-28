import 'dart:io';

import 'package:yaml/yaml.dart';

/// One entry of `package_types:` in arch_check's `rules.yaml`.
///
/// All four keys are optional and every key present has to match, which is the
/// same semantics the checker applies. Keeping them identical is the point of
/// reading the file rather than restating it: a diagram that classified a
/// package differently from the checker would be a diagram that lies.
final class TypeMatcher {
  /// Creates a matcher.
  const TypeMatcher({
    required this.typeId,
    this.path,
    this.pathPrefix,
    this.nameSuffix,
    this.nameContains,
  });

  /// The type this entry names, e.g. `feature_api`.
  final String typeId;

  /// An exact path from the workspace root.
  final String? path;

  /// A path prefix, e.g. `packages/features/`.
  final String? pathPrefix;

  /// A required suffix of the directory name.
  final String? nameSuffix;

  /// A required substring of the directory name.
  final String? nameContains;

  /// Whether a package at [relativePath] named [name] matches every key.
  bool matches({required String relativePath, required String name}) {
    if (path != null && relativePath != path) return false;
    if (pathPrefix != null && !relativePath.startsWith(pathPrefix!)) {
      return false;
    }
    if (nameSuffix != null && !name.endsWith(nameSuffix!)) return false;
    if (nameContains != null && !name.contains(nameContains!)) return false;
    return true;
  }
}

/// What this tool needs out of `rules.yaml`, and nothing more.
final class TypeRules {
  /// Creates the rules.
  const TypeRules({
    required this.matchers,
    required this.roots,
    required this.skipDirectories,
    required this.featureRoot,
  });

  /// Reads the subset of arch_check's rule file this tool uses.
  ///
  /// Throws [FormatException] when the file cannot be read or does not carry
  /// the keys, because a graph drawn from guessed types is worse than no
  /// graph.
  factory TypeRules.fromFile(String rulesPath) {
    final file = File(rulesPath);
    if (!file.existsSync()) {
      throw FormatException('no rule file at $rulesPath');
    }
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      throw FormatException('$rulesPath is not a YAML map');
    }

    final types = document['package_types'];
    if (types is! YamlList || types.isEmpty) {
      throw FormatException('$rulesPath has no package_types');
    }

    final discovery = document['discovery'];
    final roots = discovery is YamlMap ? discovery['roots'] : null;
    final skip = discovery is YamlMap ? discovery['skip_directories'] : null;

    return TypeRules(
      matchers: [
        for (final entry in types)
          if (entry is YamlMap)
            TypeMatcher(
              typeId: entry['type'].toString(),
              path: entry['path']?.toString(),
              pathPrefix: entry['path_prefix']?.toString(),
              nameSuffix: entry['name_suffix']?.toString(),
              nameContains: entry['name_contains']?.toString(),
            ),
      ],
      roots: roots is YamlList
          ? [for (final root in roots) root.toString()]
          : const ['apps', 'packages', 'tooling'],
      skipDirectories: skip is YamlList
          ? {for (final entry in skip) entry.toString()}
          : const {'.dart_tool', '.git', 'build', 'test'},
      featureRoot: document['feature_root']?.toString() ?? 'packages/features',
    );
  }

  /// The `package_types:` entries, in file order.
  final List<TypeMatcher> matchers;

  /// The directories packages are discovered under.
  final List<String> roots;

  /// Directory names never descended into.
  final Set<String> skipDirectories;

  /// The directory whose immediate children name the features.
  final String featureRoot;

  /// The one type a package resolves to, or `null` for none or more than one.
  String? typeOf({required String relativePath, required String name}) {
    final matched = {
      for (final matcher in matchers)
        if (matcher.matches(relativePath: relativePath, name: name))
          matcher.typeId,
    };
    return matched.length == 1 ? matched.single : null;
  }
}
