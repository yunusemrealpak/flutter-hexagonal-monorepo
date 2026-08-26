/// The delivery adapters: what answers its ports, the DTOs that cross the
/// wire, and the mappers between them.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:delivery_infrastructure/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

export 'src/delivery_dto.dart';
export 'src/remote_delivery_repository.dart';
