/// Enforces the dependency constitution against the workspace.
///
/// The rules are not in this library. They live in `rules.yaml`, next to the
/// document they encode, so that changing a rule is a data change a reviewer
/// can read without reading Dart.
///
/// The tool depends on nothing in `packages/` or `apps/` (rule I7). It has to
/// be able to analyze a workspace that does not compile, which is the only
/// time an architecture checker earns its place.
library;

export 'src/checks/check.dart' show Check, CheckContext;
export 'src/cli.dart' show ExitCodes, runCli;
export 'src/model/dependency.dart';
export 'src/model/package_type.dart';
export 'src/model/violation.dart';
export 'src/model/workspace.dart';
export 'src/model/workspace_package.dart';
export 'src/report.dart' show ReportFormat, render;
export 'src/rules/rule_set.dart';
export 'src/runner.dart' show ArchCheck, CheckRun;
export 'src/source_index.dart' show PackageSources, SourceFile, SourceIndex;
export 'src/workspace_loader.dart' show LoadResult, WorkspaceLoader;
