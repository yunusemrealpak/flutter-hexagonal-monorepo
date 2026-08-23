import 'package:core_ports/core_ports.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as handler;

/// The plugin's permission that corresponds to [permission].
///
/// The port names four capabilities because those are the four the product
/// asks for; the plugin knows about thirty-five. Keeping the port small is
/// what stops a feature from requesting Bluetooth because the plugin happened
/// to offer it, and this function is the only place the two vocabularies meet.
handler.Permission toHandlerPermission(DevicePermission permission) =>
    switch (permission) {
      DevicePermission.camera => handler.Permission.camera,
      DevicePermission.locationWhenInUse =>
        handler.Permission.locationWhenInUse,
      DevicePermission.locationAlways => handler.Permission.locationAlways,
      DevicePermission.notifications => handler.Permission.notification,
    };

/// The port's state that corresponds to [status].
///
/// Two of the plugin's states collapse into `granted`, and both are worth
/// naming. `limited` is partial access — the iOS photo picker's "selected
/// photos" — and `provisional` is iOS's quiet notification authorisation.
/// A caller that treated either as a denial would send a courier to the system
/// settings screen to fix something that already works.
///
/// The plugin's status enumeration has no `notDetermined`. That gap is filled
/// by `DevicePermissionRequester`, not here: this function only knows about
/// one answer at a time, and telling "never asked" from "asked and refused"
/// needs memory.
PermissionState toPermissionState(handler.PermissionStatus status) =>
    switch (status) {
      handler.PermissionStatus.granted => PermissionState.granted,
      handler.PermissionStatus.limited => PermissionState.granted,
      handler.PermissionStatus.provisional => PermissionState.granted,
      handler.PermissionStatus.denied => PermissionState.denied,
      handler.PermissionStatus.permanentlyDenied =>
        PermissionState.permanentlyDenied,
      handler.PermissionStatus.restricted => PermissionState.restricted,
    };
