import '../model/violation.dart';
import '../model/workspace.dart';
import '../rules/rule_set.dart';
import '../source_index.dart';

/// Everything a check is allowed to look at.
///
/// A check never touches the filesystem itself: the workspace was read once by
/// the loader and the sources are parsed once by the index, so adding a rule
/// costs a traversal of data already in memory rather than another pass over
/// 75 packages.
final class CheckContext {
  /// Creates the context handed to every check.
  const CheckContext({
    required this.workspace,
    required this.rules,
    required this.sources,
  });

  /// The packages under test.
  final Workspace workspace;

  /// The rules to enforce.
  final RuleSet rules;

  /// Parsed sources, read on demand and shared between checks.
  final SourceIndex sources;
}

/// One family of rules from `docs/DEPENDENCY_RULES.md`.
abstract interface class Check {
  /// The document section this check enforces, used in `--verbose` output.
  String get name;

  /// Every violation this check finds in [context].
  Iterable<Violation> run(CheckContext context);
}
