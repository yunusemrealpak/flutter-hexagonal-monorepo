/// What happened to one package's suite.
enum RunStatus {
  /// The suite ran and passed.
  passed,

  /// The suite ran and failed.
  failed,

  /// The suite was not run: its fingerprint matched a previous pass.
  skipped,
}

/// The outcome of one package.
final class PackageResult {
  /// Creates a result.
  const PackageResult({
    required this.package,
    required this.status,
    required this.duration,
    this.command = const [],
    this.fileCount,
  });

  /// The package's name.
  final String package;

  /// What happened.
  final RunStatus status;

  /// How long it took. Zero for a skip, which is the point of a skip.
  final Duration duration;

  /// The command that was run, for a report somebody has to reproduce.
  final List<String> command;

  /// How many test files a bundle pulled in, when one was used.
  final int? fileCount;

  /// Whether this counts as a failure of the whole run.
  bool get failed => status == RunStatus.failed;
}
