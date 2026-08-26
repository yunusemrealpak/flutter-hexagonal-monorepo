/// The routing contract: entities, value objects, ports and the sealed
/// failures they return.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:routing_api/src/...` is reaching across
/// a boundary, and arch_check reports it as one.
library;

export 'src/routing_failure.dart';
export 'src/routing_repository.dart';
