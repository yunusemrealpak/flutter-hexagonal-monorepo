@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_messaging/push_messaging.dart';

PushMessage _message() => PushMessage(
  id: 'msg-1',
  kind: PushMessageKind.shipmentAssigned,
  data: const {'kind': 'shipment_assigned'},
  sentAt: DateTime.utc(2026, 1, 1, 9),
);

void main() {
  late FakePushMessagingClient client;

  setUp(() => client = FakePushMessagingClient());
  tearDown(() async => client.dispose());

  group('FakePushMessagingClient', () {
    test('answers with the token it was built with', () async {
      expect(
        await client.currentToken(),
        const Success<String, PushFailure>('fake-token'),
      );
    });

    test('reports an unregistered device as a registration failure', () async {
      final unregistered = FakePushMessagingClient(token: null);
      addTearDown(unregistered.dispose);

      expect((await unregistered.currentToken()).isFailure, isTrue);
    });

    test('can be told to fail once, so failure branches stay tested', () async {
      client.failNextWith = const PushPermissionDenied();

      expect((await client.currentToken()).isFailure, isTrue);
      expect((await client.currentToken()).isSuccess, isTrue);
    });

    test('delivers a message on demand', () async {
      final seen = <PushMessage>[];
      final subscription = client.messages().listen(seen.add);
      addTearDown(subscription.cancel);

      client.deliver(_message());
      await pumpEventQueue();

      // Push is the hardest thing in the product to observe on a real device.
      // This is what makes the flows that react to one testable at all.
      expect(seen.single.kind, PushMessageKind.shipmentAssigned);
    });

    test('separates a pressed notification from a received one', () async {
      final received = <PushMessage>[];
      final pressed = <PushMessage>[];
      final subscriptions = [
        client.messages().listen(received.add),
        client.openings().listen(pressed.add),
      ];
      addTearDown(() => Future.wait(subscriptions.map((it) => it.cancel())));

      client
        ..deliver(_push(PushMessageKind.routeUpdated))
        ..open(_push(PushMessageKind.dispatchMessage));
      await pumpEventQueue();

      expect(received.single.kind, PushMessageKind.routeUpdated);
      expect(pressed.single.kind, PushMessageKind.dispatchMessage);
    });

    // The provider hands the launch message over once. A fake that kept
    // answering would hide the bug where an app navigates to the same push
    // again on its next resume.
    test('hands the launch message over exactly once', () async {
      client.launchedWith = _push(PushMessageKind.shipmentAssigned);

      expect(
        (await client.launchMessage())?.kind,
        PushMessageKind.shipmentAssigned,
      );
      expect(await client.launchMessage(), isNull);
    });

    test('tracks topic membership', () async {
      await client.subscribeTo('region-34');
      await client.subscribeTo('region-35');
      await client.unsubscribeFrom('region-34');

      expect(client.topics, {'region-35'});
    });

    test('rotates the token and announces it', () async {
      final rotated = client.tokenChanges().first;

      client.rotateToken('token-2');

      expect(await rotated, 'token-2');
      expect(
        await client.currentToken(),
        const Success<String, PushFailure>('token-2'),
      );
    });
  });
}

PushMessage _push(PushMessageKind kind) => PushMessage(
  id: 'msg-1',
  kind: kind,
  data: const {},
  sentAt: DateTime.utc(2026, 3),
);
