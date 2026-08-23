@Tags(['unit'])
library;

import 'package:core_testing/core_testing.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_messaging/push_messaging.dart';

void main() {
  late FakeClock clock;

  setUp(() => clock = FakeClock());

  group('toPushMessage', () {
    test('reads a recognised kind out of the payload', () {
      const message = RemoteMessage(
        messageId: 'msg-1',
        data: {'kind': 'shipment_assigned', 'shipment_id': 'SHP-1'},
      );

      final push = toPushMessage(message, clock: clock);

      expect(push.kind, PushMessageKind.shipmentAssigned);
      expect(push.id, 'msg-1');
    });

    test('keeps the raw payload even after reading the kind out of it', () {
      const message = RemoteMessage(
        data: {'kind': 'dispatch_message', 'thread_id': 'TH-9'},
      );

      final push = toPushMessage(message, clock: clock);

      // So a message of an unrecognised kind still carries everything a later
      // app version would have needed.
      expect(push.data, {'kind': 'dispatch_message', 'thread_id': 'TH-9'});
    });

    test('turns an unrecognised kind into unknown rather than throwing', () {
      const message = RemoteMessage(data: {'kind': 'invoice_issued'});

      final push = toPushMessage(message, clock: clock);

      // A fleet updates over weeks. A server sending a kind this version has
      // never heard of is normal traffic, not a fault.
      expect(push.kind, PushMessageKind.unknown);
      expect(push.data['kind'], 'invoice_issued');
    });

    test('survives a payload that will not decode at all', () {
      // No `kind` field: the generated fromJson throws, and the message still
      // has to arrive.
      const message = RemoteMessage(data: {'shipment_id': 'SHP-1'});

      final push = toPushMessage(message, clock: clock);

      expect(push.kind, PushMessageKind.unknown);
      expect(push.data, {'shipment_id': 'SHP-1'});
    });

    test("prefers the provider's send time over the clock", () {
      final message = RemoteMessage(
        data: const {'kind': 'route_updated'},
        sentTime: DateTime.utc(2026, 1, 1, 8),
      );

      final push = toPushMessage(message, clock: clock);

      // Push can arrive long after it was sent — a phone that was off, a
      // network that was down. Collapsing the two makes every delayed message
      // look fresh.
      expect(push.sentAt, DateTime.utc(2026, 1, 1, 8));
    });

    test('falls back to the clock when the provider sent no time', () {
      const message = RemoteMessage(data: {'kind': 'route_updated'});

      final push = toPushMessage(message, clock: clock);

      expect(push.sentAt, clock.now());
    });

    test('prefers the payload title over the notification title', () {
      const message = RemoteMessage(
        data: {'kind': 'dispatch_message', 'title': 'from the payload'},
        notification: RemoteNotification(title: 'from the envelope'),
      );

      final push = toPushMessage(message, clock: clock);

      // The payload is what the product composed; the envelope is what the
      // operating system was told to display.
      expect(push.title, 'from the payload');
    });

    test('falls back to the notification when the payload carries no text', () {
      const message = RemoteMessage(
        data: {'kind': 'dispatch_message'},
        notification: RemoteNotification(
          title: 'New message',
          body: 'Check shipment SHP-1',
        ),
      );

      final push = toPushMessage(message, clock: clock);

      expect(push.title, 'New message');
      expect(push.body, 'Check shipment SHP-1');
    });

    test('stringifies non-string payload values', () {
      const message = RemoteMessage(
        data: {'kind': 'route_updated', 'stops': 7},
      );

      final push = toPushMessage(message, clock: clock);

      expect(push.data['stops'], '7');
    });
  });
}
