import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';

/// Identifies this installation, and remembers the identifier it minted.
///
/// The identifier comes from `IdGenerator` and the moment from `Clock`, both
/// through ports — rules A1 and A3. A registry that called `Uuid()` and
/// `DateTime.now()` directly would make every test that touches sign-in
/// non-deterministic, and sign-in is on the path of every other test that
/// needs a session.
///
/// The fingerprint is a digest of characteristics the composition root
/// supplies, not something this class computes. What identifies a device is a
/// platform question — an attestation on one OS, a keystore-backed key on
/// another — and an adapter in a feature package is the wrong place to answer
/// it. What this class owns is the *rule*: the identifier is minted once and
/// reused, so a reinstall looks like a new device and a restart does not.
final class InstallationDeviceRegistry implements DeviceRegistry {
  /// Creates the registry.
  const InstallationDeviceRegistry({
    required this.store,
    required this.ids,
    required this.clock,
    required this.fingerprint,
  });

  /// Where the installation identifier is kept.
  ///
  /// A plain `KeyValueStore`, not the secure one. An installation identifier
  /// is not a secret — it names a handset, it does not authorise anything —
  /// and putting it in the keychain would make it disappear on a passcode
  /// change, turning every such change into a device the operation no longer
  /// recognises.
  final KeyValueStore store;

  /// Where a new identifier comes from.
  final IdGenerator ids;

  /// Where the binding's timestamp comes from.
  final Clock clock;

  /// The digest of this device's characteristics, supplied by the app.
  final String fingerprint;

  /// The key the installation identifier is kept under.
  static const String key = 'identity/installation';

  @override
  Future<Result<DeviceBinding, IdentityFailure>> currentBinding() async {
    final read = await store.read(key);

    return switch (read) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: final existing?) => Success(_bindingFor(existing)),
      Success(value: null) => await _mint(),
    };
  }

  @override
  Future<Result<DeviceBinding, IdentityFailure>> bind(ActorId actorId) =>
      // Binding an account to this device is the server's business; what this
      // adapter contributes is which device is being bound. Returning the
      // current binding rather than inventing a per-actor one keeps a handset
      // one device no matter who signs in on it, which is what makes "this
      // device is not one your account is bound to" a question the server can
      // answer.
      currentBinding();

  Future<Result<DeviceBinding, IdentityFailure>> _mint() async {
    final minted = ids.newId();
    final written = await store.write(key, minted);

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => Success(_bindingFor(minted)),
    };
  }

  DeviceBinding _bindingFor(String deviceId) => DeviceBinding(
    deviceId: deviceId,
    fingerprint: fingerprint,
    boundAt: clock.now(),
  );

  static IdentityFailure _translate(StoreFailure failure) => switch (failure) {
    StoreUnavailable(:final detail) => IdentityUnavailable(detail: detail),
    StoreCorrupted(:final key) => IdentityUnavailable(
      detail: 'corrupt entry at $key',
    ),
    StoreOutOfSpace() => const IdentityUnavailable(detail: 'out of space'),
  };
}
