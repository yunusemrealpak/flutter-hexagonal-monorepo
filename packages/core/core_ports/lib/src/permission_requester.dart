import 'device_permission.dart';
import 'permission_state.dart';

/// Asks the operating system for a guarded capability.
///
/// Nothing here returns a `Result`, and the reason is worth being explicit
/// about: a denied permission is not a failure. It is an outcome the product
/// has to handle as a first-class case — a courier who declines the camera
/// still has to be able to complete a delivery by another route. Modelling
/// denial as a failure invites callers to treat it as an error to report
/// rather than a state to design for.
abstract interface class PermissionRequester {
  /// The current state of [permission], without prompting the user.
  Future<PermissionState> status(DevicePermission permission);

  /// Prompts for [permission] and reports the state afterwards.
  ///
  /// Calling this when the state is already [PermissionState.permanentlyDenied]
  /// shows no prompt and returns that same state; the caller is expected to
  /// send the user to system settings instead.
  Future<PermissionState> request(DevicePermission permission);
}
