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

  /// Opens the operating system's settings page for this application.
  ///
  /// The other half of [PermissionState.permanentlyDenied], and the reason
  /// that state is distinct from [PermissionState.denied] at all: one of them
  /// can be asked again from inside the app and the other can only be changed
  /// here. A product that models both but can reach neither ends up with a
  /// screen that explains the problem and offers no way out of it.
  ///
  /// Answers whether the page was opened, not whether anything was changed
  /// there. The application is backgrounded at that point; it finds out what
  /// happened by reading [status] again when it comes back.
  ///
  /// No `Result`, like the rest of this port. A settings page that will not
  /// open is not a failure a caller can route around — there is no second way
  /// to send somebody there — so a failure branch would be one every call site
  /// had to write and none could act on.
  Future<bool> openSettings();
}
