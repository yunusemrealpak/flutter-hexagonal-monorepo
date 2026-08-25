/// The kinds of package the constitution recognises.
///
/// A package's type is derived from its path and name, never from its
/// contents. That is what makes type inference cheap, total, and impossible to
/// game by moving code around inside a package.
enum PackageType {
  /// The innermost ring. Depends on nothing at all.
  coreKernel('core_kernel'),

  /// The capabilities a feature may ask the outside world for.
  corePorts('core_ports'),

  /// Route contracts shared by presentation packages, assembled by an app.
  coreNavigation('core_navigation'),

  /// Behavioural fakes for the `core_ports` capabilities.
  coreTesting('core_testing'),

  /// A feature's contract: entities, value objects, ports and failures.
  featureApi('feature_api'),

  /// A feature's use cases. Pure Dart, and blind to every adapter.
  featureApplication('feature_application'),

  /// A feature's outbound adapters, and the DTOs and mappers they need.
  featureInfrastructure('feature_infrastructure'),

  /// Application and infrastructure together, for a feature narrow enough that
  /// splitting them would cost more than it explains.
  featureCore('feature_core'),

  /// A feature's UI. One feature may ship more than one, per app.
  featurePresentation('feature_presentation'),

  /// A feature's fakes and contract kit, consumed by other packages' tests.
  featureTesting('feature_testing'),

  /// A technology contract, its adapter, and the fake that imitates it.
  platform('platform'),

  /// Constants only: colour, spacing, type. Leaf of the design group.
  designTokens('design_tokens'),

  /// Components built from the tokens.
  designSystem('design_system'),

  /// A tool. Depends on third-party Dart packages and on no product package.
  tooling('tooling'),

  /// A composition root. The one place allowed to join everything.
  app('app');

  const PackageType(this.id);

  /// The identifier used in `rules.yaml` and in every violation message.
  final String id;

  /// The type with this identifier, or `null` if no type has it.
  static PackageType? byId(String id) {
    for (final type in PackageType.values) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// Whether a package of this type belongs to a feature, and therefore has an
  /// owning feature and an own `_api`.
  bool get isFeature => const {
    PackageType.featureApi,
    PackageType.featureApplication,
    PackageType.featureInfrastructure,
    PackageType.featureCore,
    PackageType.featurePresentation,
    PackageType.featureTesting,
  }.contains(this);

  @override
  String toString() => id;
}
