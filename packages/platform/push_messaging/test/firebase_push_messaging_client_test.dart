@Tags(['unit'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:push_messaging/push_messaging.dart';

/// A messaging platform the test drives directly.
final class FakeMessagingPlatform extends FirebaseMessagingPlatform
    with MockPlatformInterfaceMixin {
  String? nextToken = 'token-1';
  Object? throwOnGetToken;

  final List<String> subscribed = [];
  final List<String> unsubscribed = [];
  final StreamController<String> tokens = StreamController<String>.broadcast();

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    final error = throwOnGetToken;
    if (error != null) {
      // Typed as Object so the fake can reproduce anything a platform channel
      // is capable of throwing.
      // ignore: only_throw_errors
      throw error;
    }
    return nextToken;
  }

  @override
  Stream<String> get onTokenRefresh => tokens.stream;

  @override
  Future<void> subscribeToTopic(String topic) async => subscribed.add(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      unsubscribed.add(topic);
}

void main() {
  late FakeMessagingPlatform platform;
  late FakePermissionRequester permissions;
  late FakeClock clock;
  late StreamController<RemoteMessage> incoming;
  late FirebasePushMessagingClient client;

  setUp(() {
    platform = FakeMessagingPlatform();
    permissions = FakePermissionRequester({
      DevicePermission.notifications: PermissionState.granted,
    });
    clock = FakeClock();
    incoming = StreamController<RemoteMessage>.broadcast();
    client = FirebasePushMessagingClient(
      platform,
      permissions,
      clock,
      incoming: incoming.stream,
    );
  });

  tearDown(() async {
    await incoming.close();
    await platform.tokens.close();
  });

  group('currentToken', () {
    test('returns the provider token', () async {
      expect(
        await client.currentToken(),
        const Success<String, PushFailure>('token-1'),
      );
    });

    test(
      'reports a missing token as a retryable registration failure',
      () async {
        platform.nextToken = null;

        final result = await client.currentToken();

        // A courier without a token silently stops receiving assignments, and
        // nothing about the device looks wrong. Its own case so a caller can
        // retry with backoff rather than treat it as fatal.
        expect(
          (result as Failed<String, PushFailure>).failure,
          isA<PushRegistrationFailed>(),
        );
      },
    );

    test(
      'prompts when notification permission has never been asked for',
      () async {
        client = FirebasePushMessagingClient(
          platform,
          permissions = FakePermissionRequester(),
          clock,
          incoming: incoming.stream,
        );

        final result = await client.currentToken();

        // Asking for the token is what shows the iOS prompt, so the caller
        // decides when the courier is asked.
        expect(permissions.requested, [DevicePermission.notifications]);
        expect(result.isSuccess, isTrue);
      },
    );

    test(
      'keeps a refusal that can be asked again distinct from one that cannot',
      () async {
        permissions.setState(
          DevicePermission.notifications,
          PermissionState.denied,
        );
        expect(
          ((await client.currentToken()) as Failed<String, PushFailure>)
              .failure,
          isA<PushPermissionDenied>(),
        );

        permissions.setState(
          DevicePermission.notifications,
          PermissionState.permanentlyDenied,
        );
        expect(
          ((await client.currentToken()) as Failed<String, PushFailure>)
              .failure,
          isA<PushPermissionBlocked>(),
        );
      },
    );

    test('lets no exception escape', () async {
      platform.throwOnGetToken = StateError('no Firebase app');

      expect((await client.currentToken()).isFailure, isTrue);
    });
  });

  group('messages', () {
    test('maps what arrives onto a PushMessage', () async {
      final seen = <PushMessage>[];
      final subscription = client.messages().listen(seen.add);
      addTearDown(subscription.cancel);

      incoming.add(
        const RemoteMessage(
          messageId: 'msg-1',
          data: {'kind': 'shipment_assigned', 'shipment_id': 'SHP-1'},
        ),
      );
      await pumpEventQueue();

      expect(seen.single.kind, PushMessageKind.shipmentAssigned);
      expect(seen.single.id, 'msg-1');
    });

    test('keeps delivering after a payload it cannot parse', () async {
      final seen = <PushMessage>[];
      final subscription = client.messages().listen(seen.add);
      addTearDown(subscription.cancel);

      incoming
        ..add(const RemoteMessage(data: {'nothing': 'recognisable'}))
        ..add(const RemoteMessage(data: {'kind': 'route_updated'}));
      await pumpEventQueue();

      // Nothing on this stream is ever an error. An adapter that threw here
      // would take down a stream handler for a message it could have ignored.
      expect(seen.map((message) => message.kind), [
        PushMessageKind.unknown,
        PushMessageKind.routeUpdated,
      ]);
    });
  });

  group('topics', () {
    test('subscribes and unsubscribes through the platform', () async {
      expect((await client.subscribeTo('region-34')).isSuccess, isTrue);
      expect((await client.unsubscribeFrom('region-34')).isSuccess, isTrue);

      expect(platform.subscribed, ['region-34']);
      expect(platform.unsubscribed, ['region-34']);
    });
  });

  group('tokenChanges', () {
    test('passes the provider rotation through', () async {
      final rotated = client.tokenChanges().first;

      platform.tokens.add('token-2');

      // Rotation happens on reinstall and on restore from backup. A backend
      // that is not told stops being able to reach the device.
      expect(await rotated, 'token-2');
    });
  });
}
