import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import '../model/violation.dart';
import '../model/workspace_package.dart';
import 'check.dart';
import 'dependency_check.dart' show packageOfUri;

/// Section 3, everything except the cycle rule: barrels, stray files, naming,
/// workspace registration, deep imports, and implementation that ended up in a
/// contract package.
final class StructureCheck implements Check {
  /// Creates the section 3 check.
  const StructureCheck();

  @override
  String get name => 'structure (section 3)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    for (final package in context.workspace.packages) {
      yield* _naming(context, package);
      yield* _registration(context, package);
      yield* _libLayout(context, package);
      yield* _deepImports(context, package);
      yield* _implementationInApi(context, package);
    }
  }

  /// S5.
  Iterable<Violation> _naming(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    if (package.name == package.directoryName) return;
    yield Violation(
      code: 'name_mismatch',
      location: ViolationLocation(
        package: package.relativePath,
        file: '${package.relativePath}/pubspec.yaml',
      ),
      what:
          'the pubspec is named "${package.name}" but the directory is '
          '"${package.directoryName}"',
      remedy: context.rules.remedyFor('name_mismatch'),
    );
  }

  /// S6. Two halves of one rule: the root has to name the package, and the
  /// package has to opt into the shared resolution.
  Iterable<Violation> _registration(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    if (!package.isRegisteredInWorkspace) {
      yield Violation(
        code: 'unregistered_package',
        location: ViolationLocation(package: package.relativePath),
        what:
            'the root pubspec.yaml workspace: list does not contain '
            '${package.relativePath}',
        remedy: context.rules.remedyFor('unregistered_package'),
      );
    }
    if (!package.declaresWorkspaceResolution) {
      yield Violation(
        code: 'unregistered_package',
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/pubspec.yaml',
        ),
        what: '${package.name} does not declare "resolution: workspace"',
        remedy: context.rules.remedyFor('unregistered_package'),
      );
    }
  }

  /// S1, S2 and S4.
  Iterable<Violation> _libLayout(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final barrelName = '${package.name}.dart';
    final lib = Directory(p.join(package.absolutePath, 'lib'));
    final entries =
        (lib.existsSync()
              ? lib
                    .listSync(followLinks: false)
                    .whereType<File>()
                    .map((file) => p.basename(file.path))
                    .where((name) => name.endsWith('.dart'))
                    .toList()
              : <String>[])
          ..sort();

    if (!entries.contains(barrelName)) {
      yield Violation(
        code: 'missing_barrel',
        location: ViolationLocation(package: package.relativePath),
        what: 'there is no lib/$barrelName',
        remedy: context.rules.remedyFor('missing_barrel'),
      );
    }

    for (final entry in entries.where((name) => name != barrelName)) {
      yield Violation(
        code: 'stray_lib_file',
        location: ViolationLocation(
          package: package.relativePath,
          file: '${package.relativePath}/lib/$entry',
        ),
        what: '$entry sits directly under lib/, next to the barrel',
        remedy: context.rules.remedyFor('stray_lib_file'),
      );
    }

    yield* _barrelContent(context, package, barrelName);
  }

  /// S4, in the two shapes a barrel can leak: declaring a type itself, and
  /// republishing another package's surface as its own.
  Iterable<Violation> _barrelContent(
    CheckContext context,
    WorkspacePackage package,
    String barrelName,
  ) sync* {
    final barrel = context.sources
        .of(package)
        .inDirectory('lib')
        .where((file) => file.fileName == barrelName)
        .firstOrNull;
    if (barrel == null) return;

    if (!context.rules.structure.barrelAllowsDeclarations) {
      for (final declaration in barrel.unit.declarations) {
        yield Violation(
          code: 'barrel_leak',
          location: ViolationLocation(
            package: package.relativePath,
            file: barrel.relativePath,
            line: barrel.lineOf(declaration.offset),
          ),
          what:
              'the barrel declares ${_describe(declaration)} instead of only '
              're-exporting',
          remedy: context.rules.remedyFor('barrel_leak'),
        );
      }
    }

    if (!context.rules.structure.barrelAllowsPackageReexport) {
      for (final directive in barrel.unit.directives) {
        if (directive is! ExportDirective) continue;
        final uri = directive.uri.stringValue;
        if (uri == null || !uri.startsWith('package:')) continue;
        yield Violation(
          code: 'barrel_leak',
          location: ViolationLocation(
            package: package.relativePath,
            file: barrel.relativePath,
            line: barrel.lineOf(directive.offset),
          ),
          what: "the barrel re-exports '$uri'",
          remedy: context.rules.remedyFor('barrel_leak'),
        );
      }
    }
  }

  /// S3. Intra-package imports are relative by convention (CLAUDE.md section
  /// 3), so `package:*/src/` in a source file means one thing only: someone
  /// reached across a package boundary. There is no exception to weigh, not
  /// even the package's own name.
  ///
  /// Generated files are scanned too. A generated file that reaches into
  /// another package's internals is a real architectural violation regardless
  /// of who typed it; only section 5 relaxes anything for generated code.
  Iterable<Violation> _deepImports(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final scan = context.rules.structure.deepImportScan;
    for (final file in context.sources.of(package).inDirectories(scan)) {
      for (final directive in file.uriDirectives) {
        final imported = packageOfUri(directive.uri);
        if (imported == null) continue;
        if (!directive.uri.startsWith('package:$imported/src/')) continue;
        yield Violation(
          code: 'deep_import',
          location: ViolationLocation(
            package: package.relativePath,
            file: file.relativePath,
            line: directive.line,
          ),
          what: "reaches into another package's internals: '${directive.uri}'",
          remedy: context.rules.remedyFor('deep_import'),
        );
      }
    }
  }

  /// S8. A port is declared as `abstract interface class`, so a class that
  /// implements one in the same package is exact rather than a guess; a
  /// concrete class whose name ends in Impl or Adapter is the second half.
  Iterable<Violation> _implementationInApi(
    CheckContext context,
    WorkspacePackage package,
  ) sync* {
    final structure = context.rules.structure;
    if (!structure.implementationInApiTypes.contains(package.type)) return;

    final files = context.sources.of(package).inDirectory('lib').toList();
    final ports = <String>{
      for (final file in files)
        for (final declaration in file.unit.declarations)
          if (declaration is ClassDeclaration &&
              declaration.abstractKeyword != null &&
              declaration.interfaceKeyword != null)
            declaration.namePart.typeName.lexeme,
    };

    for (final file in files) {
      for (final declaration in file.unit.declarations) {
        if (declaration is! ClassDeclaration) continue;
        final className = declaration.namePart.typeName.lexeme;
        final line = file.lineOf(declaration.offset);

        final implemented = <String>[
          ...?declaration.implementsClause?.interfaces.map(
            (type) => type.name.lexeme,
          ),
          ?declaration.extendsClause?.superclass.name.lexeme,
        ].where(ports.contains).toList();

        if (implemented.isNotEmpty) {
          yield Violation(
            code: 'implementation_in_api',
            location: ViolationLocation(
              package: package.relativePath,
              file: file.relativePath,
              line: line,
            ),
            what:
                '$className implements ${implemented.join(', ')}, a port '
                'declared in this package',
            remedy: context.rules.remedyFor('implementation_in_api'),
          );
          continue;
        }

        if (declaration.abstractKeyword != null) continue;
        final suffix = structure.forbiddenClassSuffixes
            .where(className.endsWith)
            .firstOrNull;
        if (suffix == null) continue;
        yield Violation(
          code: 'implementation_in_api',
          location: ViolationLocation(
            package: package.relativePath,
            file: file.relativePath,
            line: line,
          ),
          what: 'the concrete class $className reads as an implementation',
          remedy: context.rules.remedyFor('implementation_in_api'),
        );
      }
    }
  }

  String _describe(CompilationUnitMember declaration) => switch (declaration) {
    ClassDeclaration(:final namePart) => 'class ${namePart.typeName.lexeme}',
    EnumDeclaration(:final namePart) => 'enum ${namePart.typeName.lexeme}',
    ExtensionTypeDeclaration(:final namePart) =>
      'extension type ${namePart.typeName.lexeme}',
    MixinDeclaration(:final name) => 'mixin ${name.lexeme}',
    FunctionDeclaration(:final name) => 'the function ${name.lexeme}',
    GenericTypeAlias(:final name) => 'typedef ${name.lexeme}',
    TopLevelVariableDeclaration() => 'a top-level variable',
    _ => 'a declaration',
  };
}
