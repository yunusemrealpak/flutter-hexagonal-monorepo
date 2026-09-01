@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:device_permissions/device_permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as handler;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A permission platform that answers from the test.
///
/// `PlatformInterface` rejects any instance that does not carry its token, and
/// [MockPlatformInterfaceMixin] is the sanctioned way past that check — which
/// is exactly why the adapter takes the platform as a constructor argument
/// rather than reading `PermissionHandlerPlatform.instance`. A global would
/// have made this a test that mutates process state.
final class FakePermissionHandlerPlatform
    extends handler.PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  FakePermissionHandlerPlatform(this.answer);

  /// The status every call answers with. Assign to change it mid-test.
  handler.PermissionStatus answer;

  /// Every permission [requestPermissions] was called with.
  final List<handler.Permission> requested = [];

  /// What [openAppSettings] answers. Assign to change it mid-test.
  bool settingsOpen = true;

  /// How many times [openAppSettings] was called.
  int openedAppSettings = 0;

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings++;
    return settingsOpen;
  }

  @override
  Future<handler.PermissionStatus> checkPermissionStatus(
    handler.Permission permission,
  ) async => answer;

  @override
  Future<Map<handler.Permission, handler.PermissionStatus>> requestPermissions(
    List<handler.Permission> permissions,
  ) async {
    requested.addAll(permissions);
    return {for (final permission in permissions) permission: answer};
  }
}

void main() {
  late FakePermissionHandlerPlatform platform;
  late InMemoryKeyValueStore askLog;
  late DevicePermissionRequester requester;

  setUp(() {
    platform = FakePermissionHandlerPlatform(handler.PermissionStatus.denied);
    askLog = InMemoryKeyValueStore();
    requester = DevicePermissionRequester(platform, askLog);
  });

  group('status', () {
    test('reports notDetermined for a permission never asked for', () async {
      final state = await requester.status(DevicePermission.camera);

      // The gap this adapter exists to fill: on iOS a permission that was
      // never requested reports as `denied`, the same answer the platform
      // gives for one the user actively refused.
      expect(state, PermissionState.notDetermined);
    });

    test('reports denied once the permission has been asked for', () async {
      await requester.request(DevicePermission.camera);

      expect(
        await requester.status(DevicePermission.camera),
        PermissionState.denied,
      );
    });

    test('remembers each permission separately', () async {
      await requester.request(DevicePermission.camera);

      // Asking for the camera says nothing about whether location was ever
      // asked for, and a single "have we prompted?" flag would claim it did.
      expect(
        await requester.status(DevicePermission.locationWhenInUse),
        PermissionState.notDetermined,
      );
    });

    test('passes a non-denied answer straight through', () async {
      platform.answer = handler.PermissionStatus.granted;

      // Only `denied` is ambiguous. Nothing is looked up for the others,
      // which is what keeps the common path free of a store read.
      expect(
        await requester.status(DevicePermission.camera),
        PermissionState.granted,
      );
    });

    test('reports denied when the ask log cannot be read', () async {
      askLog.failNextWith(const StoreUnavailable());

      // The conservative direction. Claiming notDetermined would prompt again
      // for something the user already refused — and on iOS the second prompt
      // is never shown, so the courier would reach a button that does nothing.
      expect(
        await requester.status(DevicePermission.camera),
        PermissionState.denied,
      );
    });
  });

  group('request', () {
    test('asks the platform for the mapped permission', () async {
      await requester.request(DevicePermission.locationAlways);

      expect(platform.requested, [handler.Permission.locationAlways]);
    });

    test('reports the state the platform answered with', () async {
      platform.answer = handler.PermissionStatus.permanentlyDenied;

      expect(
        await requester.request(DevicePermission.notifications),
        PermissionState.permanentlyDenied,
      );
    });

    test('records the ask even when the answer is a denial', () async {
      platform.answer = handler.PermissionStatus.denied;

      await requester.request(DevicePermission.camera);

      expect(askLog.entries.keys, contains('device_permissions.camera'));
    });

    test('still answers when the ask log cannot be written', () async {
      askLog.failNextWith(const StoreOutOfSpace());
      platform.answer = handler.PermissionStatus.granted;

      // Losing the record costs one extra rationale screen. Failing the
      // request because a preference could not be written would cost the
      // courier the capability itself.
      expect(
        await requester.request(DevicePermission.camera),
        PermissionState.granted,
      );
    });
  });

  group('openSettings', () {
    test('opens the application page and reports that it did', () async {
      platform.settingsOpen = true;

      expect(await requester.openSettings(), isTrue);
      expect(platform.openedAppSettings, 1);
    });

    test('reports a page that would not open', () async {
      platform.settingsOpen = false;

      // The only route out of `permanentlyDenied` is this page. A caller that
      // was told it opened when it did not would leave somebody staring at
      // the screen they were already on.
      expect(await requester.openSettings(), isFalse);
    });
  });
}
