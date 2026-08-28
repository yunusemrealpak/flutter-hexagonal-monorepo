import 'process.dart';

/// Asks git which files a change touched.
///
/// Four questions rather than one, and the union of their answers. A run
/// triggered from a pull request cares about what the branch committed; a run
/// triggered from a pre-push hook cares about that plus whatever is still in
/// the working tree. Asking only the first makes the hook pass on work that
/// has not been committed yet, which is the one moment it exists to catch.
final class GitChanges {
  /// Creates the reader.
  const GitChanges(this._commands);

  final CommandRunner _commands;

  /// Every path that differs from [base], relative to the repository root.
  ///
  /// Returns `null` when git could not answer — an unfetched base, a shallow
  /// clone, no repository at all. The caller falls back to running everything,
  /// because a selective run built on a failed diff is a run that silently
  /// covers nothing.
  Future<Set<String>?> since(String base, {required String root}) async {
    final queries = <List<String>>[
      // Committed on this branch, measured from where it left the base.
      ['diff', '--name-only', '$base...HEAD'],
      // Staged but not committed.
      ['diff', '--name-only', '--cached'],
      // Written but not staged.
      ['diff', '--name-only'],
      // Created and never added.
      ['ls-files', '--others', '--exclude-standard'],
    ];

    final paths = <String>{};
    for (final (index, arguments) in queries.indexed) {
      final result = await _commands.run(
        'git',
        arguments,
        workingDirectory: root,
      );
      // Only the first query can fail for a reason worth giving up over: a
      // base that does not exist locally. The other three cannot fail in a
      // repository that answered the first.
      if (!result.ok) {
        if (index == 0) return null;
        continue;
      }
      paths.addAll(
        result.stdout
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty),
      );
    }
    return paths;
  }
}
