/// The routing UI.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:routing_presentation/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

export 'src/routing_routes.dart';
export 'src/routing_screen.dart';
