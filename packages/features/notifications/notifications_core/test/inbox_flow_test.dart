import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:push_messaging/push_messaging.dart';

import 'support/harness.dart';

List<InboxEntry> inbox(Result<List<InboxEntry>, NotificationsFailure> read) =>
    (read as Success<List<InboxEntry>, NotificationsFailure>).value;

void main() {
  late NotificationsHarness harness;

  setUp(() => harness = NotificationsHarness());
  tearDown(() => harness.dispose());

  group('an inbox nobody has written to', () {
    test('is empty rather than missing', () async {
      final read = await harness.facade.inboxOf(NotificationsHarness.courier);

      expect(inbox(read), isEmpty);
    });
  });

  group('an alert arriving as a push', () {
    setUp(() => harness.facade.openAlertsFor(NotificationsHarness.courier));

    test('lands in the inbox, unread, stamped by the clock', () async {
      harness.deliver(id: 'push-1');
      await pumpEventQueue();

      final entries = inbox(
        await harness.facade.inboxOf(NotificationsHarness.courier),
      );
      expect(entries, hasLength(1));
      expect(entries.single.isUnread, isTrue);
      expect(entries.single.receivedAt, harness.clock.now());
      expect(entries.single.kind, NotificationKind.assignment);
      expect(entries.single.arguments['shipment'], 'SHP-42');
    });

    test('arriving twice is one alert, because the sender named it', () async {
      harness.deliver(id: 'push-1');
      await pumpEventQueue();
      harness.deliver(id: 'push-1');
      await pumpEventQueue();

      expect(
        inbox(await harness.facade.inboxOf(NotificationsHarness.courier)),
        hasLength(1),
      );
    });

    test(
      'an unnamed alert gets an identifier, and cannot be deduplicated',
      () async {
        harness.deliver(id: '');
        await pumpEventQueue();
        harness.deliver(id: '');
        await pumpEventQueue();

        final entries = inbox(
          await harness.facade.inboxOf(NotificationsHarness.courier),
        );
        expect(entries, hasLength(2));
        expect(entries.every((e) => e.id.value.startsWith('minted')), isTrue);
      },
    );

    test('a kind this version does not know is kept, not dropped', () async {
      harness.deliver(id: 'push-9', kind: PushMessageKind.unknown);
      await pumpEventQueue();

      final entries = inbox(
        await harness.facade.inboxOf(NotificationsHarness.courier),
      );
      expect(entries.single.kind, NotificationKind.unrecognised);
      expect(entries.single.arguments['shipment'], 'SHP-42');
    });

    test('the newest alert is first', () async {
      harness.deliver(id: 'push-1');
      await pumpEventQueue();
      harness.clock.advance(const Duration(minutes: 5));
      harness.deliver(id: 'push-2');
      await pumpEventQueue();

      final entries = inbox(
        await harness.facade.inboxOf(NotificationsHarness.courier),
      );
      expect(entries.map((e) => e.id.value), ['push-2', 'push-1']);
    });

    test('a storage failure is logged and the relay stays alive', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      harness.deliver(id: 'push-1');
      await pumpEventQueue();
      harness.deliver(id: 'push-2');
      await pumpEventQueue();

      expect(harness.logger.recordsAt(LogLevel.warning), isNotEmpty);
      expect(
        inbox(await harness.facade.inboxOf(NotificationsHarness.courier)),
        hasLength(1),
      );
    });
  });

  group('reading an alert', () {
    setUp(() async {
      await harness.facade.openAlertsFor(NotificationsHarness.courier);
      harness.deliver(id: 'push-1');
      await pumpEventQueue();
    });

    test('records the instant, and survives a re-read', () async {
      harness.clock.advance(const Duration(minutes: 3));
      final marked = await harness.facade.markRead(
        NotificationsHarness.courier,
        (NotificationId.parse('push-1')
                as Success<NotificationId, NotificationsFailure>)
            .value,
      );

      expect(
        (marked as Success<InboxEntry, NotificationsFailure>).value.readAt,
        harness.clock.now(),
      );
      final entries = inbox(
        await harness.facade.inboxOf(NotificationsHarness.courier),
      );
      expect(entries.single.isUnread, isFalse);
    });

    test('an alert that is not there is missing, not a fault', () async {
      final marked = await harness.facade.markRead(
        NotificationsHarness.courier,
        (NotificationId.parse('push-404')
                as Success<NotificationId, NotificationsFailure>)
            .value,
      );

      expect(
        (marked as Failed<InboxEntry, NotificationsFailure>).failure,
        isA<NotificationMissing>(),
      );
    });

    test('a second device marking it read does not move the instant', () async {
      final id =
          (NotificationId.parse('push-1')
                  as Success<NotificationId, NotificationsFailure>)
              .value;
      final first = await harness.facade.markRead(
        NotificationsHarness.courier,
        id,
      );
      harness.clock.advance(const Duration(hours: 2));

      final second = await harness.facade.markRead(
        NotificationsHarness.courier,
        id,
      );

      expect(
        (second as Success<InboxEntry, NotificationsFailure>).value.readAt,
        (first as Success<InboxEntry, NotificationsFailure>).value.readAt,
      );
    });
  });

  group('the unread count', () {
    test('follows what arrives and what is read', () async {
      final counts = <int>[];
      harness.facade.unreadCount().listen(counts.add);

      await harness.facade.openAlertsFor(NotificationsHarness.courier);
      harness.deliver(id: 'push-1');
      await pumpEventQueue();
      harness.deliver(id: 'push-2');
      await pumpEventQueue();
      await harness.facade.markRead(
        NotificationsHarness.courier,
        (NotificationId.parse('push-1')
                as Success<NotificationId, NotificationsFailure>)
            .value,
      );
      await pumpEventQueue();

      expect(counts, [0, 1, 2, 1]);
    });
  });
}
