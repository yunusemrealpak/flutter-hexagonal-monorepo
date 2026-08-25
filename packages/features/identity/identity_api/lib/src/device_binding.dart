import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_binding.freezed.dart';

/// The tie between an account and one physical device.
///
/// Peyk hands out expensive equipment and takes money at the door, so a
/// session is not just "who" but "who, on which device". The binding is what
/// makes a stolen token useless on a second handset.
///
/// Generated, unlike `Actor` and unlike `AccessToken`: it has no identity of
/// its own — a binding *is* its three fields — and it holds no secret, so a
/// structural `==` and a printing `toString` are both correct. That is the
/// line this package draws around `freezed`, and it is the same line drawn
/// around it everywhere else in the workspace: entities and secrets are
/// hand-written, closed unions and plain values are generated.
@freezed
abstract class DeviceBinding with _$DeviceBinding {
  /// Binds an account to [deviceId] as it was fingerprinted at [boundAt].
  const factory DeviceBinding({
    /// The installation's stable identifier.
    required String deviceId,

    /// A digest of the device characteristics the binding was issued against.
    required String fingerprint,

    /// When the binding was issued, in UTC, as reported by the `Clock` port.
    required DateTime boundAt,
  }) = _DeviceBinding;

  const DeviceBinding._();

  /// Whether [current] is the same device, fingerprint included.
  ///
  /// [boundAt] is deliberately not compared. A re-issued binding for the same
  /// device is the same device; comparing the timestamp would invalidate every
  /// session the moment the server refreshed a binding, which is the opposite
  /// of what the check is for.
  bool matches(DeviceBinding current) =>
      current.deviceId == deviceId && current.fingerprint == fingerprint;
}
