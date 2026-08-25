/// The identity UI.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:identity_presentation/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

export 'src/identity_routes.dart';
export 'src/identity_screen.dart';
