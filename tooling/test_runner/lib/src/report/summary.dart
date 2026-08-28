import '../model/package_result.dart';

/// The human-readable tail of a run.
abstract final class Summary {
  /// One line per package that did not pass, then the counts.
  ///
  /// Failures are listed and passes are not. A summary that printed seventy
  /// green lines would bury the one red one, and the green detail is already
  /// in the log above it.
  static String render(List<PackageResult> results) {
    final passed = results
        .where((result) => result.status == RunStatus.passed)
        .toList();
    final skipped = results
        .where((result) => result.status == RunStatus.skipped)
        .toList();
    final failed = results.where((result) => result.failed).toList();

    final total = results.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.duration,
    );

    return [
      '',
      '─' * 60,
      if (failed.isNotEmpty) ...[
        'Failed:',
        for (final result in failed)
          '  ${result.package}  (${result.command.join(' ')})',
        '',
      ],
      _counts(passed.length, failed.length, skipped.length, total),
      if (skipped.isNotEmpty) _skipped(skipped),
    ].join('\n');
  }

  static String _counts(int passed, int failed, int skipped, Duration total) =>
      'test_runner: $passed passed, $failed failed, $skipped skipped '
      'in ${_short(total)}';

  static String _skipped(List<PackageResult> skipped) {
    final names = skipped.map((result) => result.package).join(', ');
    return '  skipped because their sources have not moved since they '
        'last passed: $names';
  }

  /// The list a `--list` run prints, and the one a pull-request comment reads.
  static String listing(Iterable<String> packages) {
    final names = packages.toList();
    if (names.isEmpty) return 'test_runner: nothing to run.';
    return [
      'test_runner: ${names.length} package(s) selected',
      for (final name in names) '  $name',
    ].join('\n');
  }

  static String _short(Duration duration) {
    if (duration.inMinutes >= 1) {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes}m ${seconds}s';
    }
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }
}
