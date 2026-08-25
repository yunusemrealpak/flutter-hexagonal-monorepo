/// The shipments contract: entities, value objects, ports and the sealed
/// failures they return.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:shipments_api/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/shipments_failure.dart';
export 'src/shipments_repository.dart';
