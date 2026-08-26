import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('an arriving alert', () {
    test('is unread, and knows when it arrived', () {
      final entry = unread();

      expect(entry.isUnread, isTrue);
      expect(entry.readAt, isNull);
      expect(entry.receivedAt, arrived);
    });

    test('is stored in UTC whatever it was handed', () {
      final entry =
          (InboxEntry.arriving(
                    id: id('msg-2'),
                    kind: NotificationKind.message,
                    subject: 'inbox.message',
                    receivedAt: DateTime(2026, 3, 4, 12, 30),
                  )
                  as Success<InboxEntry, NotificationsFailure>)
              .value;

      expect(entry.receivedAt.isUtc, isTrue);
    });

    test('trims its subject and refuses an empty one', () {
      final refused = InboxEntry.arriving(
        id: id('msg-3'),
        kind: NotificationKind.announcement,
        subject: '   ',
        receivedAt: arrived,
      );

      expect(refused, isA<Failed<InboxEntry, NotificationsFailure>>());
    });

    test('cannot have its arguments changed from outside', () {
      final entry = unread();

      expect(
        () => entry.arguments['shipment'] = 'SHP-9',
        throwsUnsupportedError,
      );
    });
  });

  group('reading an alert', () {
    test('records the instant it was read at', () {
      final read = unread().readAtInstant(
        arrived.add(const Duration(hours: 1)),
      );

      expect(read.isUnread, isFalse);
      expect(read.readAt, arrived.add(const Duration(hours: 1)));
    });

    test('the first mark wins, so a second device does not move it', () {
      final first = unread().readAtInstant(arrived);

      final second = first.readAtInstant(arrived.add(const Duration(hours: 2)));

      expect(second.readAt, arrived);
      expect(second, same(first));
    });

    test('two entries with one identifier are the same alert', () {
      expect(unread(), unread().readAtInstant(arrived));
    });
  });

  group('a stored alert', () {
    test('can come back already read', () {
      final entry =
          (InboxEntry.stored(
                    id: id('msg-1'),
                    kind: NotificationKind.assignment,
                    subject: 'inbox.assignment',
                    receivedAt: arrived,
                    readAt: arrived.add(const Duration(minutes: 5)),
                  )
                  as Success<InboxEntry, NotificationsFailure>)
              .value;

      expect(entry.isUnread, isFalse);
    });

    test('cannot have been read before it arrived', () {
      final refused = InboxEntry.stored(
        id: id('msg-1'),
        kind: NotificationKind.assignment,
        subject: 'inbox.assignment',
        receivedAt: arrived,
        readAt: arrived.subtract(const Duration(minutes: 1)),
      );

      expect(refused, isA<Failed<InboxEntry, NotificationsFailure>>());
    });
  });

  group('NotificationKind', () {
    test('round-trips through its stored spelling', () {
      for (final kind in NotificationKind.values) {
        expect(
          (NotificationKind.parse(kind.name)
                  as Success<NotificationKind, NotificationsFailure>)
              .value,
          kind,
        );
      }
    });

    test(
      'an unknown spelling is a corrupt record, not an unrecognised alert',
      () {
        expect(
          NotificationKind.parse('shipmentAssigned'),
          isA<Failed<NotificationKind, NotificationsFailure>>(),
        );
      },
    );
  });

  group('NotificationId', () {
    test('trims what it is given', () {
      expect(id('  msg-1  ').value, 'msg-1');
    });

    test('refuses an empty identifier', () {
      expect(
        NotificationId.parse('  '),
        isA<Failed<NotificationId, NotificationsFailure>>(),
      );
    });
  });
}
