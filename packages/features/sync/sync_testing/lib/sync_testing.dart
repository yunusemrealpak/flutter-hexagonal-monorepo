/// Fakes and the contract kit for sync, consumed by other packages' tests.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:sync_testing/src/...` is reaching
/// across a boundary, and arch_check reports it as one.
library;

export 'src/fake_sync_repository.dart';
