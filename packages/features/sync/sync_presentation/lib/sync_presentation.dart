/// The sync UI.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:sync_presentation/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/sync_routes.dart';
export 'src/sync_screen.dart';
