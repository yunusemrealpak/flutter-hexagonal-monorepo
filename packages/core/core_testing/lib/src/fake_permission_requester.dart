import 'package:core_ports/core_ports.dart';

/// A [PermissionRequester] whose answers a test decides in advance.
///
/// Permission denial is a first-class product path, not an error path — a
/// courier who declines the camera still has to complete the delivery. That
/// path is unreachable in a test unless the answer can be scripted, which is
/// what this fake is for.
final class FakePermissionRequester implements PermissionRequester {
  /// Starts with [states]; anything unlisted is
  /// [PermissionState.notDetermined].
  FakePermissionRequester([
    Map<DevicePermission, PermissionState> states = const {},
  ]) : _states = Map<DevicePermission, PermissionState>.of(states);

  final Map<DevicePermission, PermissionState> _states;
  final List<DevicePermission> _requested = [];

  /// How many times the app sent somebody to the system settings.
  ///
  /// A count rather than a flag: a screen that opened the settings page twice
  /// for one tap is a defect, and a boolean could not tell it from working.
  int openedSettings = 0;

  /// What [openSettings] answers. Assign to script a page that will not open.
  bool settingsOpen = true;

  /// Every permission that was prompted for, in order.
  ///
  /// The assertion for "we do not ask for background location until the
  /// courier has started a shift".
  List<DevicePermission> get requested => List.unmodifiable(_requested);

  /// Sets what [permission] will report from now on.
  void setState(DevicePermission permission, PermissionState state) =>
      _states[permission] = state;

  @override
  Future<PermissionState> status(DevicePermission permission) async =>
      _states[permission] ?? PermissionState.notDetermined;

  @override
  Future<PermissionState> request(DevicePermission permission) async {
    final current = _states[permission] ?? PermissionState.notDetermined;
    // A permanently denied permission shows no prompt on a real device, so it
    // must not be recorded as one here either.
    if (current == PermissionState.permanentlyDenied ||
        current == PermissionState.restricted) {
      return current;
    }
    _requested.add(permission);
    return current == PermissionState.notDetermined
        ? PermissionState.granted
        : current;
  }

  @override
  Future<bool> openSettings() async {
    openedSettings++;
    return settingsOpen;
  }
}
