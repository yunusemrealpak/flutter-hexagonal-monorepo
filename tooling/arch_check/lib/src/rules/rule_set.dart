import 'dart:io';

import 'package:yaml/yaml.dart';

import '../model/package_type.dart';

/// Thrown when `rules.yaml` cannot be read as a rule set.
///
/// A malformed rule file is not a violation of the constitution, it is a
/// broken checker, and the two must never be confused: an unreadable rule file
/// exits with a distinct code so that CI cannot mistake it for a clean run.
final class RuleSetException implements Exception {
  /// Creates the exception with the sentence printed after `rules.yaml:`.
  const RuleSetException(this.message);

  /// What is wrong with the file, phrased to follow "rules.yaml".
  final String message;

  @override
  String toString() => 'rules.yaml: $message';
}

/// Where packages are looked for, and which directories are never descended
/// into.
final class Discovery {
  /// Creates the discovery configuration.
  const Discovery({required this.roots, required this.skipDirectories});

  /// Top-level directories that may contain packages.
  final List<String> roots;

  /// Directory names that are never descended into.
  final Set<String> skipDirectories;
}

/// One entry of the `package_types` list. Every key present must match.
final class TypeMatcher {
  /// Creates a matcher. Every key that is set must match.
  const TypeMatcher({
    required this.type,
    this.path,
    this.pathPrefix,
    this.nameSuffix,
    this.nameContains,
  });

  /// The type a matching package has.
  final PackageType type;

  /// An exact workspace-relative path.
  final String? path;

  /// A workspace-relative path prefix.
  final String? pathPrefix;

  /// A required suffix of the package name.
  final String? nameSuffix;

  /// A required substring of the package name.
  final String? nameContains;

  /// Whether a package at [relativePath] called [name] is of this type.
  bool matches({required String relativePath, required String name}) {
    if (path != null && relativePath != path) return false;
    if (pathPrefix != null && !relativePath.startsWith(pathPrefix!)) {
      return false;
    }
    if (nameSuffix != null && !name.endsWith(nameSuffix!)) return false;
    if (nameContains != null && !name.contains(nameContains!)) return false;
    // An entry with no matcher key at all would match everything, which would
    // make type inference meaningless rather than permissive.
    return path != null ||
        pathPrefix != null ||
        nameSuffix != null ||
        nameContains != null;
  }
}

/// What one package type is allowed to depend on.
final class DependencyPolicy {
  /// Creates the policy for one package type.
  const DependencyPolicy({
    required this.allow,
    required this.allowSdks,
    required this.allowThirdParty,
  });

  /// Package type ids plus the relative tokens `own_api` and `foreign_api`,
  /// plus `any`.
  final Set<String> allow;

  /// SDK names this type may depend on, such as `flutter`.
  final Set<String> allowSdks;

  /// Whether hosted pub packages are permitted at all.
  final bool allowThirdParty;

  /// Whether the policy is the app layer's, which permits every edge.
  bool get allowsAnything => allow.contains('any');
}

/// The configurable half of section 3.
final class StructureRules {
  /// Creates the configurable half of section 3.
  const StructureRules({
    required this.deepImportScan,
    required this.barrelAllowsDeclarations,
    required this.barrelAllowsPackageReexport,
    required this.implementationInApiTypes,
    required this.forbiddenClassSuffixes,
  });

  /// Package directories scanned for rule S3.
  final List<String> deepImportScan;

  /// Whether a barrel may declare a type of its own. It may not.
  final bool barrelAllowsDeclarations;

  /// Whether a barrel may re-export another package's URI. It may not.
  final bool barrelAllowsPackageReexport;

  /// The types rule S8 applies to.
  final Set<PackageType> implementationInApiTypes;

  /// Class-name suffixes that read as an implementation.
  final List<String> forbiddenClassSuffixes;
}

/// One entry of the `forbidden_imports` list.
final class ForbiddenImportRule {
  /// Creates one entry of the `forbidden_imports` list.
  const ForbiddenImportRule({
    required this.id,
    required this.code,
    required this.types,
    required this.forbiddenPrefixes,
    required this.forbidWorkspaceProducts,
    required this.scan,
  });

  /// The rule's identifier in the document, such as `I3`.
  final String id;

  /// The violation code it reports.
  final String code;

  /// The package types it applies to.
  final Set<PackageType> types;

  /// Import URI prefixes that are forbidden.
  final List<String> forbiddenPrefixes;

  /// Rule I7: instead of a fixed prefix list, every package discovered under
  /// `packages/` or `apps/` is forbidden.
  final bool forbidWorkspaceProducts;

  /// Package directories scanned for this rule.
  final List<String> scan;
}

/// How a forbidden API is recognised in the AST.
enum ApiRuleKind {
  /// Matches the textual callee of an invocation or instance creation.
  callee,

  /// Matches a `throw` inside a member whose declared return type is a
  /// `Result`, or a Future/FutureOr/Stream of one.
  throwInResultReturningMember,
}

/// One entry of `forbidden_apis.rules`.
final class ForbiddenApiRule {
  /// Creates one entry of `forbidden_apis.rules`.
  const ForbiddenApiRule({
    required this.id,
    required this.code,
    required this.kind,
    this.callees = const {},
    this.resultType = 'Result',
  });

  /// The rule's identifier in the document, such as `A1`.
  final String id;

  /// The violation code it reports.
  final String code;

  /// How the rule recognises an offence.
  final ApiRuleKind kind;

  /// The callees watched for, when [kind] is [ApiRuleKind.callee].
  final Set<String> callees;

  /// The return type that makes a `throw` a violation, for A5.
  final String resultType;
}

/// Section 5 as a whole: what to scan, what to skip, and the rules themselves.
final class ForbiddenApiRules {
  /// Creates section 5 as a whole.
  const ForbiddenApiRules({
    required this.scan,
    required this.exceptTypes,
    required this.rules,
  });

  /// Package directories scanned for these rules.
  final List<String> scan;

  /// Types exempt from all of them.
  final Set<PackageType> exceptTypes;

  /// The rules themselves.
  final List<ForbiddenApiRule> rules;
}

/// A builder that may not be enabled in a given set of package types.
final class BannedBuilder {
  /// Creates one entry of `codegen.banned_builders`.
  const BannedBuilder({
    required this.builder,
    required this.code,
    required this.types,
  });

  /// The builder's short name, as it appears in a build.yaml key.
  final String builder;

  /// The violation code it reports.
  final String code;

  /// The package types the ban applies to.
  final Set<PackageType> types;
}

/// Section 6.
final class CodegenRules {
  /// Creates section 6.
  const CodegenRules({
    required this.generatedFileSuffixes,
    required this.noCodegenTypes,
    required this.noCodegenCode,
    required this.bannedBuilders,
    required this.pinnedBuildersCode,
    required this.requireGenerateFor,
  });

  /// File suffixes that mark a file as generated.
  final List<String> generatedFileSuffixes;

  /// Types that may carry no generated file and no build.yaml.
  final Set<PackageType> noCodegenTypes;

  /// The code reported for those, rule G1.
  final String noCodegenCode;

  /// Builders that may not be enabled in a given set of types.
  final List<BannedBuilder> bannedBuilders;

  /// The code reported for rule G4.
  final String pinnedBuildersCode;

  /// Whether an enabled builder must narrow itself with `generate_for`.
  final bool requireGenerateFor;

  /// Whether [fileName] was produced by a generator.
  bool isGenerated(String fileName) =>
      generatedFileSuffixes.any(fileName.endsWith);
}

/// The whole of `rules.yaml`, parsed once.
final class RuleSet {
  /// Creates a rule set. Prefer [RuleSet.parse] or [RuleSet.fromFile].
  const RuleSet({
    required this.version,
    required this.discovery,
    required this.featureRoot,
    required this.typeMatchers,
    required this.dependencyPolicies,
    required this.structure,
    required this.forbiddenImports,
    required this.forbiddenApis,
    required this.codegen,
    required this.messages,
  });

  /// Reads and validates a rule file.
  factory RuleSet.fromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw RuleSetException('not found at $path');
    }
    return RuleSet.parse(file.readAsStringSync());
  }

  /// Reads a rule set from YAML source.
  ///
  /// Throws [RuleSetException] rather than returning a partially populated
  /// rule set: a checker running on half its rules reports a clean workspace
  /// that is not clean, which is worse than not running at all.
  factory RuleSet.parse(String source) {
    final Object? document;
    try {
      document = loadYaml(source);
    } on YamlException catch (error) {
      throw RuleSetException('is not valid YAML: ${error.message}');
    }
    if (document is! YamlMap) {
      throw const RuleSetException('must be a map at the top level');
    }

    final version = document['version'];
    if (version != 1) {
      throw RuleSetException(
        'declares version $version; this checker reads version 1',
      );
    }

    return RuleSet(
      version: 1,
      discovery: _discovery(_requireMap(document, 'discovery')),
      featureRoot: _requireString(document, 'feature_root'),
      typeMatchers: _typeMatchers(_requireList(document, 'package_types')),
      dependencyPolicies: _dependencyPolicies(
        _requireMap(document, 'dependencies'),
      ),
      structure: _structure(_requireMap(document, 'structure')),
      forbiddenImports: _forbiddenImports(
        _requireList(document, 'forbidden_imports'),
      ),
      forbiddenApis: _forbiddenApis(_requireMap(document, 'forbidden_apis')),
      codegen: _codegen(_requireMap(document, 'codegen')),
      messages: _messages(_requireMap(document, 'messages')),
    );
  }

  /// The rule file's schema version. Only 1 is understood.
  final int version;

  /// Where packages are looked for.
  final Discovery discovery;

  /// The directory whose children name the features.
  final String featureRoot;

  /// Section 1, in the order it is evaluated.
  final List<TypeMatcher> typeMatchers;

  /// Section 2, one policy per package type.
  final Map<PackageType, DependencyPolicy> dependencyPolicies;

  /// The configurable half of section 3.
  final StructureRules structure;

  /// Section 4.
  final List<ForbiddenImportRule> forbiddenImports;

  /// Section 5.
  final ForbiddenApiRules forbiddenApis;

  /// Section 6.
  final CodegenRules codegen;

  /// The remedy prose, keyed by violation code.
  final Map<String, String> messages;

  /// The remedy printed as a violation's fourth field.
  ///
  /// A missing message is a broken rule file rather than a cosmetic problem:
  /// section 7 requires every violation to say how to fix itself, so the
  /// placeholder names the gap loudly instead of printing nothing.
  ///
  /// A message may carry `{placeholder}` slots filled from [vars], which is
  /// how a remedy names the package the developer should have depended on
  /// while the sentence itself stays in rules.yaml.
  String remedyFor(String code, {Map<String, String> vars = const {}}) {
    var message =
        messages[code] ?? 'No remedy recorded in rules.yaml for code "$code".';
    for (final entry in vars.entries) {
      message = message.replaceAll('{${entry.key}}', entry.value);
    }
    return message;
  }

  /// The dependency policy for [type]. Every type has one; a rule file that
  /// omits one is rejected at load time rather than passing everything.
  DependencyPolicy policyFor(PackageType type) =>
      dependencyPolicies[type] ??
      (throw RuleSetException('declares no dependency policy for ${type.id}'));

  // -- parsing helpers ------------------------------------------------------

  static YamlMap _requireMap(YamlMap parent, String key) {
    final value = parent[key];
    if (value is! YamlMap) {
      throw RuleSetException('is missing the "$key" map');
    }
    return value;
  }

  static YamlList _requireList(YamlMap parent, String key) {
    final value = parent[key];
    if (value is! YamlList) {
      throw RuleSetException('is missing the "$key" list');
    }
    return value;
  }

  static String _requireString(YamlMap parent, String key) {
    final value = parent[key];
    if (value is! String) {
      throw RuleSetException('is missing the "$key" string');
    }
    return value;
  }

  static List<String> _strings(Object? value) {
    if (value == null) return const [];
    if (value is! YamlList) {
      throw const RuleSetException('expected a list of strings');
    }
    return value.map((entry) => entry.toString()).toList(growable: false);
  }

  static Discovery _discovery(YamlMap map) => Discovery(
    roots: _strings(map['roots']),
    skipDirectories: _strings(map['skip_directories']).toSet(),
  );

  static List<TypeMatcher> _typeMatchers(YamlList list) {
    return list
        .map((entry) {
          if (entry is! YamlMap) {
            throw const RuleSetException(
              'every package_types entry must be a map',
            );
          }
          final id = entry['type'].toString();
          final type = PackageType.byId(id);
          if (type == null) {
            throw RuleSetException('names an unknown package type "$id"');
          }
          return TypeMatcher(
            type: type,
            path: entry['path'] as String?,
            pathPrefix: entry['path_prefix'] as String?,
            nameSuffix: entry['name_suffix'] as String?,
            nameContains: entry['name_contains'] as String?,
          );
        })
        .toList(growable: false);
  }

  static Map<PackageType, DependencyPolicy> _dependencyPolicies(YamlMap map) {
    final policies = <PackageType, DependencyPolicy>{};
    for (final entry in map.entries) {
      final id = entry.key.toString();
      final type = PackageType.byId(id);
      if (type == null) {
        throw RuleSetException(
          'declares a dependency policy for the unknown type "$id"',
        );
      }
      final value = entry.value;
      if (value is! YamlMap) {
        throw RuleSetException('the dependency policy for "$id" must be a map');
      }
      policies[type] = DependencyPolicy(
        allow: _strings(value['allow']).toSet(),
        allowSdks: _strings(value['allow_sdks']).toSet(),
        allowThirdParty: value['allow_third_party'] as bool? ?? true,
      );
    }
    // Every type needs a policy: an unlisted type would otherwise be checked
    // against nothing and pass everything.
    for (final type in PackageType.values) {
      if (!policies.containsKey(type)) {
        throw RuleSetException('declares no dependency policy for ${type.id}');
      }
    }
    return policies;
  }

  static Set<PackageType> _resolveTypes(Object? inTypes, Object? exceptTypes) {
    final included = _strings(inTypes);
    final excluded = _strings(exceptTypes).map(_typeById).toSet();
    final resolved = included.contains('*')
        ? PackageType.values.toSet()
        : included.map(_typeById).toSet();
    return resolved.difference(excluded);
  }

  static PackageType _typeById(String id) {
    final type = PackageType.byId(id);
    if (type == null) {
      throw RuleSetException('names an unknown package type "$id"');
    }
    return type;
  }

  static StructureRules _structure(YamlMap map) {
    final deepImport = _requireMap(map, 'deep_import');
    final barrel = _requireMap(map, 'barrel');
    final implementation = _requireMap(map, 'implementation_in_api');
    return StructureRules(
      deepImportScan: _strings(deepImport['scan']),
      barrelAllowsDeclarations: barrel['allow_declarations'] as bool? ?? false,
      barrelAllowsPackageReexport:
          barrel['allow_package_reexport'] as bool? ?? false,
      implementationInApiTypes: _resolveTypes(
        implementation['in_types'],
        implementation['except_types'],
      ),
      forbiddenClassSuffixes: _strings(
        implementation['forbidden_class_suffixes'],
      ),
    );
  }

  static List<ForbiddenImportRule> _forbiddenImports(YamlList list) {
    return list
        .map((entry) {
          if (entry is! YamlMap) {
            throw const RuleSetException(
              'every forbidden_imports entry must be a map',
            );
          }
          return ForbiddenImportRule(
            id: entry['id'].toString(),
            code: entry['code'].toString(),
            types: _resolveTypes(entry['in_types'], entry['except_types']),
            forbiddenPrefixes: _strings(entry['forbid']),
            forbidWorkspaceProducts:
                entry['forbid_workspace_products'] as bool? ?? false,
            scan: _strings(entry['scan']),
          );
        })
        .toList(growable: false);
  }

  static ForbiddenApiRules _forbiddenApis(YamlMap map) {
    final rules = _requireList(map, 'rules')
        .map((entry) {
          if (entry is! YamlMap) {
            throw const RuleSetException(
              'every forbidden_apis rule must be a map',
            );
          }
          final kindId = entry['kind'].toString();
          final kind = switch (kindId) {
            'callee' => ApiRuleKind.callee,
            'throw_in_result_returning_member' =>
              ApiRuleKind.throwInResultReturningMember,
            _ => throw RuleSetException(
              'names an unknown api rule kind "$kindId"',
            ),
          };
          return ForbiddenApiRule(
            id: entry['id'].toString(),
            code: entry['code'].toString(),
            kind: kind,
            callees: _strings(entry['callees']).toSet(),
            resultType: entry['result_type'] as String? ?? 'Result',
          );
        })
        .toList(growable: false);

    return ForbiddenApiRules(
      scan: _strings(map['scan']),
      exceptTypes: _strings(map['except_types']).map(_typeById).toSet(),
      rules: rules,
    );
  }

  static CodegenRules _codegen(YamlMap map) {
    final noCodegen = _requireMap(map, 'no_codegen_in');
    final pinned = _requireMap(map, 'pinned_builders');
    final banned = _requireList(map, 'banned_builders')
        .map((entry) {
          if (entry is! YamlMap) {
            throw const RuleSetException(
              'every banned_builders entry must be a map',
            );
          }
          return BannedBuilder(
            builder: entry['builder'].toString(),
            code: entry['code'].toString(),
            types: _resolveTypes(entry['in_types'], entry['except_types']),
          );
        })
        .toList(growable: false);

    return CodegenRules(
      generatedFileSuffixes: _strings(map['generated_file_suffixes']),
      noCodegenTypes: _strings(noCodegen['types']).map(_typeById).toSet(),
      noCodegenCode: noCodegen['code'].toString(),
      bannedBuilders: banned,
      pinnedBuildersCode: pinned['code'].toString(),
      requireGenerateFor: pinned['require_generate_for'] as bool? ?? true,
    );
  }

  static Map<String, String> _messages(YamlMap map) {
    return {
      for (final entry in map.entries)
        entry.key.toString(): entry.value.toString().trim(),
    };
  }
}
