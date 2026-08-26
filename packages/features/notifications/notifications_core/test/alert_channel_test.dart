import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_core/notifications_core.dart';
import 'package:push_messaging/push_messaging.dart';

import 'support/harness.dart';

PushMessage push({
  String id = 'push-1',
  PushMessageKind kind = PushMessageKind.shipmentAssigned,
  Map<String, String> data = const {},
}) => PushMessage(
  id: id,
  kind: kind,
  data: data,
  sentAt: DateTime.utc(2026, 3, 4, 9),
);

void main() {
  group('the provider translation', () {
    test('every push kind has a product kind', () {
      const expected = {
        PushMessageKind.shipmentAssigned: NotificationKind.assignment,
        PushMessageKind.dispatchMessage: NotificationKind.message,
        PushMessageKind.routeUpdated: NotificationKind.routeChange,
        PushMessageKind.unknown: NotificationKind.unrecognised,
      };

      for (final entry in expected.entries) {
        expect(
          PushAlertChannel.toAlert(push(kind: entry.key)).kind,
          entry.value,
        );
      }
      expect(expected.keys.toSet(), PushMessageKind.values.toSet());
    });

    test('a message with no identifier arrives unnamed', () {
      expect(PushAlertChannel.toAlert(push(id: '')).externalId, isNull);
    });

    test('the payload survives translation whole', () {
      final alert = PushAlertChannel.toAlert(
        push(kind: PushMessageKind.unknown, data: {'anything': 'at all'}),
      );

      expect(alert.arguments, {'anything': 'at all'});
    });
  });

  group('opening alerts', () {
    late NotificationsHarness harness;

    setUp(() => harness = NotificationsHarness());
    tearDown(() => harness.dispose());

    test('subscribes this device to the actor topic', () async {
      await harness.facade.openAlertsFor(NotificationsHarness.courier);

      expect(harness.push.topics, {
        PushAlertChannel.topicFor(NotificationsHarness.courier.value),
      });
    });

    test('closing unsubscribes it again', () async {
      await harness.facade.openAlertsFor(NotificationsHarness.courier);

      await harness.facade.closeAlertsFor(NotificationsHarness.courier);

      expect(harness.push.topics, isEmpty);
    });

    test('a refusal is an answer a screen can act on', () async {
      harness.push.failNextWith = const PushPermissionDenied();

      final opened = await harness.facade.openAlertsFor(
        NotificationsHarness.courier,
      );

      expect(
        (opened as Failed<void, NotificationsFailure>).failure,
        isA<AlertsRefused>(),
      );
      expect(harness.push.topics, isEmpty);
    });

    test('a block is a different answer from a refusal', () async {
      harness.push.failNextWith = const PushPermissionBlocked();

      final opened = await harness.facade.openAlertsFor(
        NotificationsHarness.courier,
      );

      expect(
        (opened as Failed<void, NotificationsFailure>).failure,
        isA<AlertsBlocked>(),
      );
    });

    test('nothing is recorded until alerts are open', () async {
      harness.deliver(id: 'push-1');
      await pumpEventQueue();

      final read = await harness.facade.inboxOf(NotificationsHarness.courier);
      expect(
        (read as Success<List<InboxEntry>, NotificationsFailure>).value,
        isEmpty,
      );
    });
  });
}
