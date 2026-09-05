import 'package:core_kernel/core_kernel.dart';

import '../../failures/identity_failure.dart';
import '../../values/actor_id.dart';
import '../../values/device_binding.dart';

/// Tells identity which device it is running on, and ties an account to it.
///
/// The fingerprint this port produces is the input to the rule in
/// `Session.validateAgainst`: a session presented on a device whose
/// fingerprint no longer matches is refused. Where the fingerprint comes from
/// — an installation identifier, a keystore-backed key, an attestation — is
/// the adapter's business and changes nothing here.
abstract interface class DeviceRegistry {
  /// Describes the device the app is running on right now.
  ///
  /// Returns a binding whether or not an account has been tied to it: the
  /// `deviceId` and `fingerprint` are properties of the handset, and
  /// `boundAt` is when they were last read.
  Future<Result<DeviceBinding, IdentityFailure>> currentBinding();

  /// Ties [actorId]'s account to this device and returns the issued binding.
  Future<Result<DeviceBinding, IdentityFailure>> bind(ActorId actorId);
}
