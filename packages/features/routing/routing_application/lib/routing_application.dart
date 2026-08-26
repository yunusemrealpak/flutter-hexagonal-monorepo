/// The routing use cases. Pure Dart, and blind to every adapter that answers
/// its ports.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:routing_application/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

export 'src/load_routing.dart';
