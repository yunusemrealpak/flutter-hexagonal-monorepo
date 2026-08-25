/// Fakes and the contract kit for identity, consumed by other packages'
/// tests.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:identity_testing/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/fake_identity_repository.dart';
