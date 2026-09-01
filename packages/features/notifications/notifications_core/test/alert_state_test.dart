@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:push_messaging/push_messaging.dart';

import 'support/harness.dart';

/// The two facts an alert state is made of, and every way they combine.
///
/// The provider exposes no way to read which topics a device is subscribed to,
/// so "this device opened alerts for this actor" has to be remembered. That
/// makes the stored fact capable of disagreeing with the operating system —
/// somebody turns notifications off in the phone's own settings and the
/// registry still says open — which is what most of this file is about.
void main() {
  late NotificationsHarness harness;
  late String actorId;

  setUp(() {
    harness = NotificationsHarness();
    actorId = NotificationsHarness.courier.value;
  });

  tearDown(() => harness.dispose());

  /// The state for the actor every test acts as.
  Future<AlertState> stateOf([ActorId? actor]) async {
    final result = await harness.facade.alertStateFor(
      actor ?? NotificationsHarness.courier,
    );
    return result.fold(
      (state) => state,
      (failure) => throw StateError('expected a state, got $failure'),
    );
  }

  /// Whether the registry says this device opened alerts for [id].
  Future<bool> registryHolds(String id) async {
    final result = await harness.registry.isOpenFor(id);
    return result.fold(
      (open) => open,
      (failure) => throw StateError('expected a flag, got $failure'),
    );
  }

  void permitted(PermissionState state) =>
      harness.permissions.setState(DevicePermission.notifications, state);

  group('the state of alerts', () {
    test(
      'is open when the permission is granted and the device opened it',
      () async {
        permitted(PermissionState.granted);
        await harness.registry.rememberOpen(actorId);

        expect(await stateOf(), isA<AlertsOpen>());
      },
    );

    test(
      'is closed when the permission is granted but nobody opened it',
      () async {
        permitted(PermissionState.granted);

        expect(await stateOf(), isA<AlertsClosed>());
      },
    );

    test('is closed before anybody has been asked', () async {
      // notDetermined, which is where every device starts.
      expect(await stateOf(), isA<AlertsClosed>());
    });

    test(
      'is closed when the permission was refused and can be asked again',
      () async {
        permitted(PermissionState.denied);
        await harness.registry.rememberOpen(actorId);

        // The registry says open and the operating system says no. Reading the
        // registry alone would draw a switch that is on while nothing arrives.
        expect(await stateOf(), isA<AlertsClosed>());
      },
    );

    test('is unavailable when the app may not ask again', () async {
      permitted(PermissionState.permanentlyDenied);

      expect(await stateOf(), isA<AlertsUnavailable>());
    });

    test('is unavailable when device policy forbids it', () async {
      permitted(PermissionState.restricted);

      expect(await stateOf(), isA<AlertsUnavailable>());
    });

    test('answers unavailable without reading the registry', () async {
      permitted(PermissionState.permanentlyDenied);
      harness.keyValue.failNextWith(const StoreUnavailable());

      // A device that may not be asked again has no use for the stored fact,
      // so this row cannot fail on a store read.
      expect(await stateOf(), isA<AlertsUnavailable>());
    });

    test(
      'fails rather than guessing when the registry cannot be read',
      () async {
        permitted(PermissionState.granted);
        harness.keyValue.failNextWith(const StoreUnavailable());

        final result = await harness.facade.alertStateFor(
          NotificationsHarness.courier,
        );

        expect(
          result,
          isA<Failed<AlertState, NotificationsFailure>>().having(
            (failed) => failed.failure,
            'failure',
            isA<AlertStateUnavailable>(),
          ),
        );
      },
    );

    test('follows one actor at a time', () async {
      permitted(PermissionState.granted);
      await harness.registry.rememberOpen(actorId);

      // A handset is signed into by one person, but the store outlives the
      // session. The next courier must not inherit the last one's answer.
      expect(
        await stateOf(NotificationsHarness.actor('courier-8')),
        isA<AlertsClosed>(),
      );
    });
  });

  group('opening alerts', () {
    test('remembers that this device opened them', () async {
      final opened = await harness.facade.openAlertsFor(
        NotificationsHarness.courier,
      );

      expect(opened.isSuccess, isTrue);
      expect(await registryHolds(actorId), isTrue);
    });

    test('records nothing when the channel refused', () async {
      harness.push.failNextWith = const PushPermissionDenied();

      final opened = await harness.facade.openAlertsFor(
        NotificationsHarness.courier,
      );

      expect(opened.isFailure, isTrue);
      // Recording an open that did not happen is how a switch ends up on
      // while the device receives nothing.
      expect(await registryHolds(actorId), isFalse);
    });
  });

  group('closing alerts', () {
    test('forgets that this device opened them', () async {
      await harness.facade.openAlertsFor(NotificationsHarness.courier);

      final closed = await harness.facade.closeAlertsFor(
        NotificationsHarness.courier,
      );

      expect(closed.isSuccess, isTrue);
      expect(await registryHolds(actorId), isFalse);
    });

    test('keeps the record when the channel could not close', () async {
      await harness.facade.openAlertsFor(NotificationsHarness.courier);
      harness.push.failNextWith = const PushUnavailable(detail: 'no network');

      final closed = await harness.facade.closeAlertsFor(
        NotificationsHarness.courier,
      );

      expect(closed.isFailure, isTrue);
      // The device is still subscribed. Forgetting would record a state the
      // device does not have, and the screen would offer to open what is
      // already open.
      expect(await registryHolds(actorId), isTrue);
    });
  });
}
