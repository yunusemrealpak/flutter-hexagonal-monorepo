/// Which packages a feature gets, and how they are split.
enum FeatureSplit {
  /// `_api`, `_application`, `_infrastructure`, `_presentation`, and
  /// optionally `_testing`. For a feature with real business rules, more than
  /// one outbound adapter, or offline behaviour.
  full('full'),

  /// `_api`, `_core`, `_presentation`. The starting point for a narrow
  /// feature: application and infrastructure share a package until there is a
  /// reason for them not to.
  reduced('reduced');

  const FeatureSplit(this.id);

  /// The value accepted by `--split`.
  final String id;

  /// The split with this identifier, or `null` if there is none.
  static FeatureSplit? byId(String id) {
    for (final split in FeatureSplit.values) {
      if (split.id == id) return split;
    }
    return null;
  }
}

/// The role a generated package plays, which decides everything else about it:
/// its dependency list, whether it binds Flutter, what seed source it gets,
/// and which builder it would enable if code generation were asked for.
enum PackageRole {
  /// The contract. Separate in every split, because it is the only thing that
  /// resolves cycles and narrows the blast radius of a change.
  api('_api'),

  /// The use cases. Pure Dart, blind to every adapter.
  application('_application'),

  /// The outbound adapters, their DTOs and their mappers.
  infrastructure('_infrastructure'),

  /// Application and infrastructure in one package, for the reduced split.
  core('_core'),

  /// The UI. A feature may ship more than one, per app.
  presentation('_presentation'),

  /// Fakes and contract kits other packages' tests consume.
  testing('_testing');

  const PackageRole(this.suffix);

  /// The suffix appended to the feature name.
  final String suffix;
}

/// One package the scaffolder will write.
final class PackagePlan {
  /// Describes a package to generate.
  const PackagePlan({
    required this.name,
    required this.relativePath,
    required this.role,
    required this.description,
    required this.dependencies,
    required this.devDependencies,
    required this.usesFlutter,
    required this.builder,
  });

  /// The package name, which is also its directory name.
  final String name;

  /// Posix path relative to the workspace root.
  final String relativePath;

  /// What the package is for.
  final PackageRole role;

  /// The pubspec `description:`.
  final String description;

  /// Workspace package names, sorted. The Flutter SDK is not in here — see
  /// [usesFlutter].
  final List<String> dependencies;

  /// Third-party and workspace names used only by `test/`.
  final List<String> devDependencies;

  /// Whether the package binds the Flutter SDK, which also decides which test
  /// runner melos uses for it.
  final bool usesFlutter;

  /// The builder this package would enable under `--codegen`, or `null` when
  /// no builder belongs here.
  final String? builder;
}

/// Everything the scaffolder is about to create for one feature.
final class FeaturePlan {
  /// Builds the plan. Prefer [FeaturePlan.of], which applies the constitution.
  const FeaturePlan({
    required this.feature,
    required this.split,
    required this.packages,
  });

  /// Works out which packages a feature gets and what each may depend on.
  ///
  /// [existingPackages] is the set of package names already in the workspace.
  /// A dependency that is not there yet is left out rather than written into
  /// a pubspec that cannot resolve — `design_system` does not exist until
  /// phase 5, and a presentation package generated before then must still run
  /// `dart pub get`. The generated README says which dependency was skipped
  /// and when to add it.
  factory FeaturePlan.of({
    required String feature,
    required FeatureSplit split,
    required Set<String> existingPackages,
    List<String> presentationVariants = const [''],
    bool withTesting = false,
  }) {
    final roles = <PackageRole>[
      PackageRole.api,
      if (split == FeatureSplit.full) ...[
        PackageRole.application,
        PackageRole.infrastructure,
      ] else
        PackageRole.core,
      if (withTesting) PackageRole.testing,
    ];

    String? ifPresent(String name) =>
        existingPackages.contains(name) ? name : null;

    final packages = <PackagePlan>[
      for (final role in roles)
        _plan(
          feature: feature,
          role: role,
          variant: '',
          ifPresent: ifPresent,
          withTesting: withTesting,
        ),
      for (final variant in presentationVariants)
        _plan(
          feature: feature,
          role: PackageRole.presentation,
          variant: variant,
          ifPresent: ifPresent,
          withTesting: withTesting,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));

    return FeaturePlan(feature: feature, split: split, packages: packages);
  }

  /// The feature's directory name under `packages/features/`.
  final String feature;

  /// Which split was chosen.
  final FeatureSplit split;

  /// The packages to write, ordered by name.
  final List<PackagePlan> packages;

  /// The feature's contract package.
  String get apiName => '${feature}_api';

  static PackagePlan _plan({
    required String feature,
    required PackageRole role,
    required String variant,
    required String? Function(String) ifPresent,
    required bool withTesting,
  }) {
    final api = '${feature}_api';
    final name = variant.isEmpty
        ? '$feature${role.suffix}'
        : '$feature${role.suffix}_$variant';

    // The dependency lists below are section 2 of docs/DEPENDENCY_RULES.md,
    // one row each. Nothing is added "because it will probably be needed":
    // a dependency that is not used yet is a dependency nobody removes.
    final (
      List<String?> dependencies,
      List<String?> devDependencies,
      bool flutter,
      String? builder,
      String description,
    ) = switch (role) {
      PackageRole.api => (
        ['core_kernel', ifPresent('core_ports')],
        ['test'],
        false,
        'freezed',
        'The $feature contract: entities, value objects, ports and the sealed '
            'failures they return.',
      ),
      PackageRole.application => (
        [api, 'core_kernel', ifPresent('core_ports')],
        [
          'test',
          ifPresent('core_testing'),
          if (withTesting) '${feature}_testing',
        ],
        false,
        null,
        'The $feature use cases. Pure Dart, and blind to every adapter that '
            'answers its ports.',
      ),
      PackageRole.infrastructure => (
        [api, 'core_kernel', ifPresent('core_ports')],
        [
          'test',
          ifPresent('core_testing'),
          if (withTesting) '${feature}_testing',
        ],
        false,
        'json_serializable',
        'The $feature adapters: what answers its ports, the DTOs that cross '
            'the wire, and the mappers between them.',
      ),
      PackageRole.core => (
        [api, 'core_kernel', ifPresent('core_ports')],
        ['test', ifPresent('core_testing')],
        false,
        'json_serializable',
        'The $feature use cases and adapters, together. Split them apart the '
            'day one of them grows a second reason to change.',
      ),
      PackageRole.presentation => (
        [
          api,
          'core_kernel',
          ifPresent('core_navigation'),
          ifPresent('design_system'),
        ],
        ['flutter_test'],
        true,
        'go_router_builder',
        variant.isEmpty
            ? 'The $feature UI.'
            : 'The $feature UI as $variant sees it.',
      ),
      PackageRole.testing => (
        [
          api,
          'core_kernel',
          ifPresent('core_ports'),
          ifPresent('core_testing'),
        ],
        ['test'],
        false,
        null,
        "Fakes and the contract kit for $feature, consumed by other packages' "
            'tests.',
      ),
    };

    return PackagePlan(
      name: name,
      relativePath: 'packages/features/$feature/$name',
      role: role,
      description: description,
      dependencies: dependencies.nonNulls.toList()..sort(),
      devDependencies: devDependencies.nonNulls.toList()..sort(),
      usesFlutter: flutter,
      builder: builder,
    );
  }
}
