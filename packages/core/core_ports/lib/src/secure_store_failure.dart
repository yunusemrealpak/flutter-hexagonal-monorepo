import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/src/secure_store.dart';

/// Why a [SecureStore] operation did not complete.
///
/// Separate from `StoreFailure` because secure storage fails for reasons plain
/// storage cannot: the keychain may be locked, or the platform may demand a
/// biometric prompt the user dismissed. A caller has to be able to tell "the
/// disk is broken" from "the user said no", and a shared failure type would
/// hide that difference.
sealed class SecureStoreFailure extends Failure {
  const SecureStoreFailure();
}

/// The secure enclave or keychain is not available on this device or build.
final class SecureStoreUnavailable extends SecureStoreFailure {
  /// Records that secure storage is not usable here.
  const SecureStoreUnavailable();

  @override
  String toString() => 'SecureStoreUnavailable()';
}

/// The platform required the user to authenticate and the attempt did not
/// succeed — dismissed, cancelled, or failed.
final class SecureStoreAuthenticationFailed extends SecureStoreFailure {
  /// Records that the platform's authentication gate was not passed.
  const SecureStoreAuthenticationFailed();

  @override
  String toString() => 'SecureStoreAuthenticationFailed()';
}

/// The entry exists but could not be decrypted.
///
/// Normally means the key material was invalidated — a new device passcode, a
/// restored backup, a reinstall. The value is unrecoverable and the caller
/// should treat the credential as gone rather than retry.
final class SecureStoreKeyInvalidated extends SecureStoreFailure {
  /// Records that the stored entry can no longer be decrypted.
  const SecureStoreKeyInvalidated();

  @override
  String toString() => 'SecureStoreKeyInvalidated()';
}
