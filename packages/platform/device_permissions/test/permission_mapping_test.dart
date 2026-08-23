@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:device_permissions/device_permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as handler;

void main() {
  group('toHandlerPermission', () {
    test('maps every permission the port declares', () {
      expect(
        DevicePermission.values.map(toHandlerPermission),
        [
          handler.Permission.camera,
          handler.Permission.locationWhenInUse,
          handler.Permission.locationAlways,
          handler.Permission.notification,
        ],
      );
    });
  });

  group('toPermissionState', () {
    test('treats limited and provisional access as granted', () {
      // Partial access — the iOS photo picker's "selected photos", iOS's quiet
      // notification authorisation — already works. Treating either as a
      // denial would send a courier to the settings screen to fix something
      // that is not broken.
      expect(
        toPermissionState(handler.PermissionStatus.limited),
        PermissionState.granted,
      );
      expect(
        toPermissionState(handler.PermissionStatus.provisional),
        PermissionState.granted,
      );
    });

    test('keeps a permanent denial distinct from a plain one', () {
      // The two lead to different screens: one prompts again, the other can
      // only be resolved in system settings.
      expect(
        toPermissionState(handler.PermissionStatus.denied),
        PermissionState.denied,
      );
      expect(
        toPermissionState(handler.PermissionStatus.permanentlyDenied),
        PermissionState.permanentlyDenied,
      );
    });

    test('maps a policy restriction to its own state', () {
      expect(
        toPermissionState(handler.PermissionStatus.restricted),
        PermissionState.restricted,
      );
    });
  });
}
