import 'checks/api_check.dart';
import 'checks/check.dart';
import 'checks/dependency_check.dart';
import 'checks/import_check.dart';
import 'checks/structure_check.dart';
import 'model/violation.dart';
import 'rules/rule_set.dart';
import 'source_index.dart';
import 'workspace_loader.dart';

/// What one run of the checker produced.
final class CheckRun {
  /// Creates the outcome of one run.
  const CheckRun({
    required this.violations,
    required this.packagesChecked,
    required this.checksRun,
  });

  /// Every violation found, sorted by location.
  final List<Violation> violations;

  /// How many typed packages were checked.
  final int packagesChecked;

  /// The names of the checks that ran, in order.
  final List<String> checksRun;

  /// Whether the workspace obeys the constitution.
  bool get isClean => violations.isEmpty;

  /// Violation counts by code, for the summary line.
  /// How many violations each code produced, ordered by code.
  Map<String, int> get countsByCode {
    final counts = <String, int>{};
    for (final violation in violations) {
      counts[violation.code] = (counts[violation.code] ?? 0) + 1;
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

/// Runs every check against one workspace.
///
/// The order the checks run in does not affect the output — violations are
/// sorted by location before they are reported — so a new check can be added
/// to the list without thinking about where.
final class ArchCheck {
  /// Creates a checker that enforces [rules].
  const ArchCheck(this.rules);

  /// Creates a checker from a rule file on disk.
  factory ArchCheck.fromRulesFile(String path) =>
      ArchCheck(RuleSet.fromFile(path));

  /// The rules being enforced.
  final RuleSet rules;

  /// One check per section of the dependency rules.
  static const List<Check> checks = [
    DependencyCheck(),
    StructureCheck(),
    ImportCheck(),
    ApiCheck(),
  ];

  /// Checks the workspace rooted at [rootPath].
  CheckRun run(String rootPath) {
    final loaded = WorkspaceLoader(rules).load(rootPath);
    final context = CheckContext(
      workspace: loaded.workspace,
      rules: rules,
      sources: SourceIndex(loaded.workspace),
    );

    final violations = <Violation>[...loaded.violations];
    for (final check in checks) {
      violations.addAll(check.run(context));
    }
    violations.sort();

    return CheckRun(
      violations: violations,
      packagesChecked: loaded.workspace.packages.length,
      checksRun: checks.map((check) => check.name).toList(growable: false),
    );
  }
}
