/// Fakes and the contract kit for delivery, consumed by other packages'
/// tests.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:delivery_testing/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/fake_delivery_repository.dart';
