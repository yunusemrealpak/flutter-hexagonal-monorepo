import 'feature_plan.dart';
import 'naming.dart';

/// The files one generated package consists of, keyed by their path relative
/// to the package directory.
///
/// Templates live in one place rather than next to each role's logic, because
/// the thing a reviewer needs to check is that they agree with each other: the
/// barrel exports what the seed declares, the test imports what the barrel
/// exports, and the README describes the pubspec that sits beside it.
Map<String, String> filesFor(
  PackagePlan package,
  FeaturePlan plan, {
  required bool codegen,
}) {
  final naming = Naming(plan.feature, variant: _variantOf(package, plan));
  return {
    'pubspec.yaml': _pubspec(package, codegen: codegen),
    'README.md': _readme(package, plan, codegen: codegen),
    'dart_test.yaml': _dartTest(package),
    if (codegen && package.builder != null) 'build.yaml': _buildYaml(package),
    'lib/${package.name}.dart': _barrel(package, naming),
    ..._sources(package, naming),
    'test/${package.name}_test.dart': _test(package, naming),
  };
}

String _variantOf(PackagePlan package, FeaturePlan plan) {
  if (package.role != PackageRole.presentation) return '';
  final prefix = '${plan.feature}${PackageRole.presentation.suffix}';
  if (package.name.length <= prefix.length) return '';
  return package.name.substring(prefix.length + 1);
}

// ---------------------------------------------------------------------------
// pubspec
// ---------------------------------------------------------------------------

String _pubspec(PackagePlan package, {required bool codegen}) {
  // Every entry is rendered into a name-keyed map and emitted in sorted
  // order. `sort_pub_dependencies` is an error in this workspace, and the
  // orderings that break it are not the obvious ones: an SDK dependency on
  // `flutter` sorts before a feature named `vehicle_inventory` and after one
  // named `billing`, so appending it is right about half the time.
  final dependencies = <String, String>{
    for (final dependency in package.dependencies)
      dependency: '  $dependency: ^0.1.0',
    if (package.usesFlutter) 'flutter': '  flutter:\n    sdk: flutter',
  };

  final devDependencies = <String, String>{
    for (final dependency in package.devDependencies)
      dependency: switch (dependency) {
        'test' => '  test: ^1.26.0',
        'flutter_test' => '  flutter_test:\n    sdk: flutter',
        _ => '  $dependency: ^0.1.0',
      },
    if (codegen && package.builder != null) ...{
      'build_runner': '  build_runner: ^2.16.0',
      package.builder!: '  ${package.builder}: ${_builderConstraint(package)}',
    },
  };

  final buffer = StringBuffer()
    ..writeln('name: ${package.name}')
    ..writeln('description: >-')
    ..writeln(_wrap(package.description, indent: '  '))
    ..writeln('publish_to: none')
    ..writeln('version: 0.1.0')
    ..writeln('resolution: workspace')
    ..writeln()
    ..writeln('environment:')
    ..writeln('  sdk: ^3.12.0');
  if (package.usesFlutter) {
    buffer.writeln('  flutter: ">=3.44.0"');
  }

  buffer
    ..writeln()
    ..writeln(
      '# Exactly the dependency list section 2 of docs/DEPENDENCY_RULES.md '
      'allows for',
    )
    ..writeln(
      '# a ${package.role.name} package. Adding one that is not in that row '
      'is a violation,',
    )
    ..writeln('# not an exception — arch_check will say which rule and why.')
    ..writeln('dependencies:')
    ..writeAll(_sortedValues(dependencies), '\n')
    ..writeln()
    ..writeln()
    ..writeln('dev_dependencies:')
    ..writeAll(_sortedValues(devDependencies), '\n')
    ..writeln();
  return buffer.toString();
}

Iterable<String> _sortedValues(Map<String, String> entries) {
  final keys = entries.keys.toList()..sort();
  return keys.map((key) => entries[key]!);
}

/// The version of each generator that resolves against this workspace.
///
/// These are pinned rather than left as `any` because the workspace shares one
/// dependency solution: a generator that wants an older analyzer than
/// arch_check does makes the whole repository unresolvable, and the error pub
/// prints for that names two packages that have nothing to do with each other.
String _builderConstraint(PackagePlan package) => switch (package.builder) {
  'freezed' => '^4.0.0',
  'json_serializable' => '^6.14.0',
  'go_router_builder' => '^4.4.0',
  _ => 'any',
};

// ---------------------------------------------------------------------------
// build.yaml — only written under --codegen
// ---------------------------------------------------------------------------

String _buildYaml(PackagePlan package) =>
    '''
# Only ${package.builder} generates here, and only from lib/src.
#
# The `generate_for` narrowing is not cosmetic: without it build_runner offers
# every file in the package to the builder, including the barrel and the test
# directory. Across 75 packages that scan is the difference between a codegen
# run measured in seconds and one measured in minutes.
#
# Rule G4 also asks that the rest be disabled explicitly, and "the rest" means
# the rest of what is actually present: naming a builder that is not a dev
# dependency of this package fails the build rather than tightening it.
targets:
  \$default:
    builders:
      ${package.builder}:
        enabled: true
        generate_for:
          - lib/src/**.dart
      source_gen:combining_builder:
        options:
          ignore_for_file:
            - type=lint
''';

// ---------------------------------------------------------------------------
// dart_test.yaml
// ---------------------------------------------------------------------------

String _dartTest(PackagePlan package) {
  // Wrapped rather than hard-wrapped in the template: the sentence starts
  // with the package name, so where it needs to break depends on how long
  // that name is.
  final runner = _wrap(
    package.usesFlutter
        ? '${package.name} depends on the Flutter SDK, so its tests run '
              'under `flutter test` (melos: `test:flutter`) rather than '
              '`dart test`.'
        : '${package.name} is pure Dart with no Flutter binding, so only the '
              'tags a pure Dart package can produce are declared here.',
    indent: '# ',
  );
  final widgetTags = package.usesFlutter
      ? '  widget:\n    timeout: 60s\n  golden:\n    timeout: 2x\n'
      : '';
  final prExclusions = package.usesFlutter ? 'golden || flaky' : 'flaky';
  return '''
# Mirrors the workspace template at the repository root. The test package reads
# the file next to the pubspec being tested, so every package carries its own
# copy; tooling/scaffold generates it per package type.
#
$runner
retry: 0
timeout: 30s

tags:
  unit:
$widgetTags  flaky:
    retry: 2
    timeout: 2x

presets:
  pr:
    exclude_tags: $prExclusions
  quarantine:
    include_tags: flaky
''';
}

// ---------------------------------------------------------------------------
// barrel
// ---------------------------------------------------------------------------

String _barrel(PackagePlan package, Naming naming) {
  final exports = _sources(
    package,
    naming,
  ).keys.map((path) => path.substring('lib/'.length)).toList()..sort();
  final body = exports.map((path) => "export '$path';").join('\n');
  return '''
${_wrap(package.description, indent: '/// ')}
///
${_wrap('Everything this package publishes is exported here and nowhere else. '
  'Another package importing `package:${package.name}/src/...` is reaching '
  'across a boundary, and arch_check reports it as one.', indent: '/// ')}
library;

$body
''';
}

// ---------------------------------------------------------------------------
// seed sources
// ---------------------------------------------------------------------------

Map<String, String> _sources(PackagePlan package, Naming naming) =>
    switch (package.role) {
      PackageRole.api => _apiSources(naming),
      PackageRole.application => _applicationSources(naming),
      PackageRole.infrastructure => _infrastructureSources(naming),
      PackageRole.core => {
        ..._applicationSources(naming),
        ..._infrastructureSources(naming),
      },
      PackageRole.presentation => _presentationSources(package, naming),
      PackageRole.testing => _testingSources(naming),
    };

/// Renders an import block the way `directives_ordering` wants it: `package:`
/// imports first and alphabetical, then a blank line, then relative ones.
///
/// Sorting is done here rather than written into each template because the
/// order depends on the feature's name. `billing_api` sorts before
/// `core_kernel` and `faq_api` sorts after it, so a hand-written template is
/// correct for roughly half the features anyone will scaffold — which is the
/// worst possible failure rate, because it passes the first time it is tried.
String _imports({
  required List<String> packages,
  List<String> relative = const [],
}) {
  final lines = (packages.toList()..sort())
      .map((uri) => "import 'package:$uri';")
      .join('\n');
  if (relative.isEmpty) return lines;
  final locals = (relative.toList()..sort())
      .map((uri) => "import '$uri';")
      .join('\n');
  return '$lines\n\n$locals';
}

Map<String, String> _apiSources(Naming naming) {
  final feature = naming.feature;
  final type = naming.featurePascal;
  return {
    'lib/src/${feature}_failure.dart':
        '''
import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the $feature ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather
/// than in an adapter, because a failure is part of a contract: the package
/// that owns the port owns what failing it means.
sealed class ${type}Failure extends Failure {
  /// Const so that a failure can be built in a const context.
  const ${type}Failure();
}

/// Nothing is stored under the identifier that was asked for.
final class ${type}NotFound extends ${type}Failure {
  /// Creates the failure for [id].
  const ${type}NotFound(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => '${type}NotFound(\$id)';
}

/// The outside world could not be reached, so nothing is known either way.
///
${_wrap('Distinct from [${type}NotFound] on purpose: "absent" and "unknown" call for different behaviour in the caller, and collapsing them is how a retry becomes a deletion.', indent: '/// ')}
final class ${type}Unavailable extends ${type}Failure {
  /// Creates the failure.
  const ${type}Unavailable();

  @override
  String toString() => '${type}Unavailable()';
}
''',
    'lib/src/${feature}_repository.dart':
        '''
import 'package:core_kernel/core_kernel.dart';

import '${feature}_failure.dart';

/// What $feature needs from the outside world, in the product's words.
///
/// A port, not a technology contract: it says nothing about HTTP, a database
/// or a device. An adapter in an implementation package answers it *using* a
/// technology, and an app's composition root decides which one.
///
/// The method returns a [Result] because it can fail. Rule 1.2.9 forbids an
/// exception crossing this boundary — an adapter catches whatever its
/// technology throws and returns a [${type}Failure] instead.
abstract interface class ${type}Repository {
  /// Loads the record stored under [id].
  Future<Result<String, ${type}Failure>> byId(String id);
}
''',
  };
}

Map<String, String> _applicationSources(Naming naming) {
  final feature = naming.feature;
  final type = naming.featurePascal;
  return {
    'lib/src/load_$feature.dart':
        '''
${_imports(packages: ['${feature}_api/${feature}_api.dart', 'core_kernel/core_kernel.dart'])}

/// One product intention: read a $feature record by its identifier.
///
/// Every collaborator arrives through the constructor. That constructor is
/// the whole dependency story of the class — there is no locator inside a
/// package and no global to reach for — which is why a test can run this
/// against a fake without any setup at all.
final class Load$type
    implements UseCase<String, Result<String, ${type}Failure>> {
  /// Creates the use case over the port it reads through.
  ///
  /// Positional and private: a named parameter cannot be an initializing
  /// formal for a private field, and spelling the assignment out instead
  /// trips `prefer_initializing_formals`. One collaborator does not need a
  /// label to be readable.
  const Load$type(this._repository);

  final ${type}Repository _repository;

  @override
  Future<Result<String, ${type}Failure>> call(String input) =>
      _repository.byId(input);
}
''',
  };
}

Map<String, String> _infrastructureSources(Naming naming) {
  final feature = naming.feature;
  final type = naming.featurePascal;
  return {
    'lib/src/${feature}_dto.dart':
        '''
/// The wire shape of a $feature record.
///
/// A DTO, and it stays here. It never appears in a signature the domain can
/// see: the adapter maps it to whatever the port promised, so a change to the
/// server's field names is a change to this file and its mapper, and to
/// nothing else.
final class ${type}Dto {
  /// Creates the DTO.
  const ${type}Dto({required this.id});

  /// Reads one from a decoded JSON object.
  ///
  /// Hand-written while this package has no generator wired up. Add
  /// `json_serializable` and a `build.yaml` when the shape grows past what is
  /// pleasant to write by hand — never in the `_api` package.
  factory ${type}Dto.fromJson(Map<String, Object?> json) =>
      ${type}Dto(id: json['id']! as String);

  /// The identifier as the remote system spells it.
  final String id;

  /// The domain value this DTO carries.
  ///
  /// The mapper lives beside the DTO rather than beside the entity, because
  /// mapping is an infrastructure concern and the domain must not learn the
  /// wire format to do it.
  String toDomain() => id;
}
''',
    'lib/src/remote_${feature}_repository.dart':
        '''
${_imports(packages: ['${feature}_api/${feature}_api.dart', 'core_kernel/core_kernel.dart'], relative: ['${feature}_dto.dart'])}

/// Answers the $feature contract from a remote system.
///
/// A scaffolded stub: it reports [${type}Unavailable] until a transport is
/// given to it. Take that transport through the constructor as a technology
/// contract from a `platform/*` package — never a client library directly, and
/// never a service locator.
///
/// Whatever that technology throws is caught here and returned as a failure.
/// No exception crosses this boundary.
final class Remote${type}Repository implements ${type}Repository {
  /// Creates the adapter.
  const Remote${type}Repository();

  @override
  Future<Result<String, ${type}Failure>> byId(String id) async {
    return const Failed<String, ${type}Failure>(${type}Unavailable());
  }

  /// Maps a decoded payload to the value the port promised.
  ///
  /// Kept separate from the call above so that the mapping can be tested
  /// without a transport, which is most of what is worth testing here.
  String fromPayload(Map<String, Object?> payload) =>
      ${type}Dto.fromJson(payload).toDomain();
}
''',
  };
}

Map<String, String> _presentationSources(PackagePlan package, Naming naming) {
  final type = naming.pascal;
  final sources = <String, String>{
    'lib/src/${naming.snake}_screen.dart':
        '''
import 'package:flutter/widgets.dart';

/// The $type screen.
///
/// Presentation depends on its feature's `_api` and never on its
/// `_application` or `_infrastructure`: it knows the vocabulary, not the use
/// cases and not the adapters. An app's composition root supplies whatever
/// this screen needs to call.
final class ${type}Screen extends StatelessWidget {
  /// Creates the screen.
  const ${type}Screen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''',
  };

  if (package.dependencies.contains('core_navigation')) {
    sources['lib/src/${naming.snake}_routes.dart'] =
        '''
import 'package:core_navigation/core_navigation.dart';

/// The destinations this package offers.
///
/// The app collects a module from every presentation package it includes and
/// builds its router from the union, which is why this type carries no router
/// library: `app_courier` and `app_dispatcher` include different features and
/// neither feature has to know which app it ended up in.
final class ${type}Routes implements RouteModule {
  /// Creates the module.
  const ${type}Routes();

  @override
  String get moduleName => '${naming.snake}';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: '${naming.snake}.home', path: '/${naming.snake}'),
  ];
}
''';
  }
  return sources;
}

Map<String, String> _testingSources(Naming naming) {
  final feature = naming.feature;
  final type = naming.featurePascal;
  return {
    'lib/src/fake_${feature}_repository.dart':
        '''
${_imports(packages: ['${feature}_api/${feature}_api.dart', 'core_kernel/core_kernel.dart'])}

/// A fake, not a mock: it really stores what it is given and really returns
/// it.
///
/// A test written against this exercises the caller's logic rather than a
/// script of expected calls, which is why it keeps passing when the caller is
/// refactored and starts failing when the caller is broken.
///
/// Failure is part of the port's contract, so the fake can produce it —
/// otherwise every caller's failure branch stays untested.
final class Fake${type}Repository implements ${type}Repository {
  final Map<String, String> _records = {};
  final List<${type}Failure> _queuedFailures = [];

  /// Makes [id] resolve to [value].
  void give(String id, String value) => _records[id] = value;

  /// Makes the next call fail with [failure], whatever is stored.
  ///
  /// A queue rather than a single slot, so a test can line up two failures
  /// and assert on a retry.
  void failNextWith(${type}Failure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<String, ${type}Failure>> byId(String id) async {
    if (_queuedFailures.isNotEmpty) {
      return Failed<String, ${type}Failure>(_queuedFailures.removeAt(0));
    }
    final found = _records[id];
    return found == null
        ? Failed<String, ${type}Failure>(${type}NotFound(id))
        : Success<String, ${type}Failure>(found);
  }
}
''',
  };
}

// ---------------------------------------------------------------------------
// tests
// ---------------------------------------------------------------------------

String _test(PackagePlan package, Naming naming) {
  final feature = naming.feature;
  final type = naming.featurePascal;
  final harness = package.usesFlutter
      ? "import 'package:flutter_test/flutter_test.dart';"
      : "import 'package:test/test.dart';";

  final body = switch (package.role) {
    PackageRole.api =>
      '''
  group('${type}Failure', () {
    test('is exhaustively matchable', () {
      const failures = <${type}Failure>[
        ${type}NotFound('id'),
        ${type}Unavailable(),
      ];

      final described = failures
          .map(
            (failure) => switch (failure) {
              ${type}NotFound(:final id) => 'missing \$id',
              ${type}Unavailable() => 'unknown',
            },
          )
          .toList();

      expect(described, ['missing id', 'unknown']);
    });
  });
''',
    PackageRole.application || PackageRole.core =>
      '''
  group('Load$type', () {
    test('returns what the repository holds', () async {
      final repository = _StubRepository()..records['id'] = 'value';
      final useCase = Load$type(repository);

      final result = await useCase('id');

      expect(result.isSuccess, isTrue);
      expect(result.fold((value) => value, (failure) => '\$failure'), 'value');
    });

    test('passes a failure through untouched', () async {
      final repository = _StubRepository();
      final useCase = Load$type(repository);

      final result = await useCase('missing');

      expect(result.isFailure, isTrue);
    });
  });
''',
    PackageRole.infrastructure =>
      '''
  group('Remote${type}Repository', () {
    test('reports unavailable until a transport is supplied', () async {
      const repository = Remote${type}Repository();

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });

    test('maps a payload without touching a transport', () {
      const repository = Remote${type}Repository();

      expect(repository.fromPayload({'id': 'value'}), 'value');
    });
  });
''',
    PackageRole.presentation =>
      '''
  group('${naming.pascal}Screen', () {
    testWidgets('builds', (tester) async {
      await tester.pumpWidget(const ${naming.pascal}Screen());

      expect(find.byType(${naming.pascal}Screen), findsOneWidget);
    });
  });
''',
    PackageRole.testing =>
      '''
  group('Fake${type}Repository', () {
    test('returns what it was given', () async {
      final repository = Fake${type}Repository()..give('id', 'value');

      final result = await repository.byId('id');

      expect(result.fold((value) => value, (failure) => '\$failure'), 'value');
    });

    test('can be told to fail, so failure branches stay tested', () async {
      final repository = Fake${type}Repository()
        ..give('id', 'value')
        ..failNextWith(const ${type}Unavailable());

      final result = await repository.byId('id');

      expect(result.isFailure, isTrue);
    });
  });
''',
  };

  final stub =
      package.role == PackageRole.application ||
          package.role == PackageRole.core
      ? '''

/// A stub kept local to this file rather than pulled from a `_testing`
/// package, so that a freshly scaffolded feature has a passing test before it
/// has anything else.
final class _StubRepository implements ${type}Repository {
  final Map<String, String> records = {};

  @override
  Future<Result<String, ${type}Failure>> byId(String id) async {
    final found = records[id];
    return found == null
        ? Failed<String, ${type}Failure>(${type}NotFound(id))
        : Success<String, ${type}Failure>(found);
  }
}
'''
      : '';

  // Exactly what the body above uses. An unused import in a generated file is
  // a warning the person who ran the scaffolder has to clean up before their
  // first commit, which is a bad first impression for a tool whose whole
  // claim is that its output is already correct.
  final needsApi = const {
    PackageRole.application,
    PackageRole.core,
    PackageRole.testing,
  }.contains(package.role);
  final needsKernel = const {
    PackageRole.application,
    PackageRole.core,
  }.contains(package.role);

  final imports = <String>{
    if (needsApi) "import 'package:${feature}_api/${feature}_api.dart';",
    if (needsKernel) "import 'package:core_kernel/core_kernel.dart';",
    "import 'package:${package.name}/${package.name}.dart';",
    harness,
  }.toList()..sort();

  return '''
@Tags(['unit'])
library;

${imports.join('\n')}

void main() {
$body}
$stub''';
}

// ---------------------------------------------------------------------------
// README
// ---------------------------------------------------------------------------

String _readme(PackagePlan package, FeaturePlan plan, {required bool codegen}) {
  final allowed = [
    ...package.dependencies,
    if (package.usesFlutter) 'the Flutter SDK',
  ].join('`, `');

  final never = _mustNeverLiveHere(package.role, plan.feature);

  final codegenNote = codegen && package.builder != null
      ? 'This package was generated with `--codegen`, so it carries a '
            '`build.yaml` that enables `${package.builder}` and narrows it to '
            '`lib/src`. Nothing is generated yet; the wiring is there so that '
            'the first annotated type needs no configuration.'
      : package.builder != null
      ? 'There is no `build.yaml` and no `build_runner` dependency, because '
            'nothing here is generated yet — that is the cheapest '
            'configuration, not a missing one. When the first annotated type '
            'arrives, add a `build.yaml` that enables `${package.builder}` and '
            'narrows it with `generate_for: [lib/src/**.dart]`.'
      : 'Nothing is generated here, and nothing should be.';

  return '''
# ${package.name}

${package.description}

## What it may depend on

`$allowed`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

## What must never live here

${never.map((line) => '- $line').join('\n')}

## Code generation

$codegenNote

## Generated by

`dart run tooling/scaffold/bin/scaffold.dart new-feature --name ${plan.feature} --split ${plan.split.id}`

Everything in `lib/src` is a seed: it compiles, it is tested, and it is meant to be replaced. Delete what you do not need — a scaffolded file that survives untouched into a real feature is a file nobody read.
''';
}

/// The "what must never live here" bullets for one role.
///
/// Built with a list and `add` rather than as a literal, because a literal of
/// adjacent strings is what `no_adjacent_strings_in_list` exists to catch: in
/// a list of prose it is one missing comma away from silently merging two
/// entries.
List<String> _mustNeverLiveHere(PackageRole role, String feature) {
  final bullets = <String>[];
  switch (role) {
    case PackageRole.api:
      bullets
        ..add(
          '**An implementation of a port declared here.** The class that '
          'satisfies a port belongs in an implementation package or in a fake.',
        )
        ..add(
          '**A DTO, or `json_annotation`.** Serialization is an '
          'infrastructure concern; a DTO in a contract package leaks the wire '
          'format into the domain.',
        )
        ..add(
          '**The Flutter SDK.** This package is pure Dart, which is what '
          'keeps the fast majority of the suite fast.',
        );
    case PackageRole.application:
      bullets
        ..add(
          '**Anything from `platform/*`.** A use case that reaches for a '
          'driven adapter has stopped being testable without a device.',
        )
        ..add(
          "**Another feature's `_application`, `_infrastructure` or "
          '`_presentation`.** Features meet through `_api` only.',
        )
        ..add(
          '**`DateTime.now()`, `Random()` or `Uuid()`.** They arrive as ports '
          'from `core_ports`, which is what makes a test deterministic.',
        );
    case PackageRole.infrastructure:
      bullets
        ..add(
          '**A use case.** This package answers ports; it does not '
          'orchestrate them.',
        )
        ..add(
          "**A foreign feature's `_api`.** If an adapter needs another "
          "feature's concept, the crossing belongs to a use case.",
        )
        ..add(
          '**A throw that escapes.** Catch what the technology raises and '
          'return a sealed failure.',
        );
    case PackageRole.core:
      bullets
        ..add(
          "**Another feature's implementation packages.** Features meet "
          'through `_api` only.',
        )
        ..add(
          '**A reason to stay merged.** Split into `_application` and '
          '`_infrastructure` the day one half grows a second reason to change.',
        );
    case PackageRole.presentation:
      bullets
        ..add(
          '**`${feature}_application`, `${feature}_infrastructure` or any '
          '`_core`.** Presentation knows the vocabulary, not the use cases and '
          'not the adapters; the app wires them together.',
        )
        ..add('**Anything from `platform/*`.**')
        ..add(
          '**A colour or a spacing value of its own.** Those come from '
          '`design_system`.',
        );
    case PackageRole.testing:
      bullets
        ..add(
          '**A mock.** Fakes here really do the thing, so a test survives a '
          'refactor of its subject.',
        )
        ..add(
          '**An implementation package.** This package depends on contracts '
          'only.',
        );
  }
  return bullets;
}

/// Wraps prose to fit a pubspec's folded block scalar without a line running
/// past 80 columns.
String _wrap(String text, {required String indent, int width = 78}) {
  final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final lines = <String>[];
  var current = StringBuffer(indent);
  var empty = true;
  for (final word in words) {
    if (!empty && current.length + 1 + word.length > width) {
      lines.add(current.toString());
      current = StringBuffer(indent);
      empty = true;
    }
    if (!empty) current.write(' ');
    current.write(word);
    empty = false;
  }
  if (!empty) lines.add(current.toString());
  return lines.join('\n');
}
