/// Decides which packages a change can break, runs them, and reports.
///
/// Six capabilities, in the order they compose: select the affected packages
/// from a git diff, choose the runner each one needs, optionally bundle its
/// test files into one entrypoint, skip whatever has not moved since it last
/// passed, split what is left across machines by measured cost, and report the
/// result as JUnit XML and as a summary.
///
/// It depends on nothing in `packages/`, `apps/` or `tooling/` (§2 gives a
/// tooling package an empty allow-list), and it enumerates the workspace from
/// the root pubspec's `workspace:` list — the same list pub resolves against.
library;

export 'src/affected.dart' show AffectedPackages;
export 'src/bucketing.dart' show bucketOf;
export 'src/bundle.dart' show TestBundle;
export 'src/cache.dart' show TestHashCache;
export 'src/cli.dart' show ExitCodes, runCli;
export 'src/git.dart' show GitChanges;
export 'src/hashing.dart' show PackageHasher;
export 'src/model/package_result.dart';
export 'src/model/test_package.dart';
export 'src/process.dart'
    show CommandResult, CommandRunner, SystemCommandRunner;
export 'src/report/junit.dart' show JUnitReport;
export 'src/report/summary.dart' show Summary;
export 'src/runner.dart' show SuiteRunner;
export 'src/timings.dart' show Timings;
export 'src/workspace.dart' show WorkspaceReader;
