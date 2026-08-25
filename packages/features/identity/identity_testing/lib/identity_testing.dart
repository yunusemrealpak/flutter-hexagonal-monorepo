/// Fakes, fixtures and a contract kit for identity.
///
/// `SessionBuilder` produces a valid, unremarkable session by default, so a
/// test names only the thing it is about — an expired token, a broken device
/// binding — and the rest stays out of the way.
///
/// The fakes carry behaviour rather than a script. `FakeCredentialGateway`
/// really issues a session bound to the device it was handed, which is what
/// stops a use case forgetting to pass the right binding; `FakeDeviceRegistry`
/// can change its mind between calls, which is the only way the
/// broken-binding rule can be reached at all.
///
/// `runSessionStoreContract` is one suite, run here against the in-memory
/// store and in `identity_infrastructure` against the keychain-backed one. A
/// session store is the piece most likely to be reimplemented per platform and
/// the piece where a behavioural difference is least visible: an app that
/// quietly forgot a session on restart looks like a login bug.
library;

export 'src/fake_credential_gateway.dart';
export 'src/fake_device_registry.dart';
export 'src/in_memory_session_store.dart';
export 'src/session_builder.dart';
export 'src/session_store_contract.dart';
