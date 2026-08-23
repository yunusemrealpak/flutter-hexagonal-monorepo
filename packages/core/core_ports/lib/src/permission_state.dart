import 'package:core_ports/src/device_permission.dart';

/// Where a [DevicePermission] currently stands.
enum PermissionState {
  /// The user has not been asked yet.
  notDetermined,

  /// The user granted it.
  granted,

  /// The user declined, and asking again is still allowed.
  denied,

  /// The user declined in a way that stops the app from asking again. The only
  /// remaining route is the system settings screen.
  permanentlyDenied,

  /// Policy on the device forbids it, independently of the user's wishes —
  /// managed device configuration, parental controls.
  restricted,
}
