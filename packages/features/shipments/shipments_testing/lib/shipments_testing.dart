/// Fakes and the contract kit for shipments, consumed by other packages'
/// tests.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:shipments_testing/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/fake_shipments_repository.dart';
