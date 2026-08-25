import '../model/package_type.dart';
import '../model/violation.dart';
import '../rules/rule_set.dart';
import 'check.dart';
import 'dependency_check.dart' show packageOfUri;

/// Section 4.
///
/// Imports are checked in generated files too. A generated file that imports a
/// package the constitution forbids is a real architectural violation
/// regardless of who typed it — only the forbidden-API rules of section 5 are
/// relaxed for generated code, and for a different reason.
final class ImportCheck implements Check {
  /// Creates the section 4 and S3 check.
  const ImportCheck();

  @override
  String get name => 'forbidden imports (section 4)';

  @override
  Iterable<Violation> run(CheckContext context) sync* {
    for (final rule in context.rules.forbiddenImports) {
      for (final package in context.workspace.packages) {
        if (!rule.types.contains(package.type)) continue;
        for (final file
            in context.sources.of(package).inDirectories(rule.scan)) {
          for (final directive in file.uriDirectives) {
            final what = _offence(context, rule, directive.uri);
            if (what == null) continue;
            yield Violation(
              code: rule.code,
              location: ViolationLocation(
                package: package.relativePath,
                file: file.relativePath,
                line: directive.line,
              ),
              what: what,
              remedy: context.rules.remedyFor(rule.code),
            );
          }
        }
      }
    }
  }

  String? _offence(
    CheckContext context,
    ForbiddenImportRule rule,
    String uri,
  ) {
    if (rule.forbidWorkspaceProducts) {
      final imported = packageOfUri(uri);
      if (imported == null) return null;
      final target = context.workspace.byName(imported);
      if (target == null || target.type == PackageType.tooling) return null;
      return "imports the product package $imported: '$uri'";
    }
    final matched = rule.forbiddenPrefixes.where(uri.startsWith).firstOrNull;
    if (matched == null) return null;
    return "imports '$uri'";
  }
}
