/// The keychain-backed adapter for the `SecureStore` port.
///
/// One adapter and one translation function, and the translation is the part
/// worth reading. A platform channel reports failure as a `PlatformException`
/// carrying strings its native side composed — there is no enumeration to
/// switch on — so recognising "the user dismissed the biometric prompt" from
/// "the key material is gone" means matching on message fragments. That is
/// brittle, it is what the platform offers, and
/// `secure_store_failure_mapping.dart` says so in its own comments rather than
/// pretending otherwise.
///
/// What makes the brittleness affordable is where it sits. It is in one file,
/// below a port whose three failure cases are stable, and its catch-all is the
/// retryable one — so a reworded platform message degrades the diagnosis
/// instead of inverting it. A caller sees `SecureStoreFailure` and never a
/// `PlatformException`, which is the whole point of putting an adapter here.
///
/// There is no in-memory implementation in this package. `core_testing`
/// already ships `InMemorySecureStore`, and a second one here would be a
/// second thing to keep in step with the port.
library;

export 'src/keychain_secure_store.dart';
export 'src/secure_store_failure_mapping.dart';
