import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

final DateTime written = DateTime.utc(2026, 3, 4, 9, 15);

ActorId get courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

ActorId get dispatcher =>
    (ActorId.parse('dispatch-1') as Success<ActorId, IdentityFailure>).value;

ShipmentId get parcel =>
    (ShipmentId.parse('SHP-42') as Success<ShipmentId, ShipmentFailure>).value;

Message message({String body = 'Gate code, please', ActorId? author}) =>
    (Message.written(
              id:
                  (MessageId.parse('MSG-1')
                          as Success<MessageId, MessagingFailure>)
                      .value,
              thread: ThreadId.aboutShipment(parcel),
              author: author ?? courier,
              body: body,
              writtenAt: written,
            )
            as Success<Message, MessagingFailure>)
        .value;

void main() {
  group('a written message', () {
    test('is queued, and knows when it was written', () {
      final one = message();

      expect(one.isQueued, isTrue);
      expect(one.isRead, isFalse);
      expect(one.writtenAt, written);
    });

    test('is trimmed, and an empty body is refused', () {
      expect(message(body: '  hello  ').body, 'hello');
      expect(
        Message.written(
          id: (MessageId.parse('MSG-2') as Success<MessageId, MessagingFailure>)
              .value,
          thread: ThreadId.aboutShipment(parcel),
          author: courier,
          body: '   ',
          writtenAt: written,
        ),
        isA<Failed<Message, MessagingFailure>>(),
      );
    });

    test('is stored in UTC whatever it was handed', () {
      final one =
          (Message.written(
                    id:
                        (MessageId.parse('MSG-3')
                                as Success<MessageId, MessagingFailure>)
                            .value,
                    thread: ThreadId.aboutShipment(parcel),
                    author: courier,
                    body: 'local time',
                    writtenAt: DateTime(2026, 3, 4, 12),
                  )
                  as Success<Message, MessagingFailure>)
              .value;

      expect(one.writtenAt.isUtc, isTrue);
    });
  });

  group('sending', () {
    test('records the server instant and leaves the queue', () {
      final sent = message().sentAtInstant(
        written.add(const Duration(seconds: 2)),
      );

      expect(sent.isQueued, isFalse);
      expect(sent.sentAt, written.add(const Duration(seconds: 2)));
    });

    test('the first acknowledgement wins, so a retry does not move it', () {
      final first = message().sentAtInstant(written);

      final second = first.sentAtInstant(written.add(const Duration(hours: 1)));

      expect(second.sentAt, written);
      expect(second, same(first));
    });
  });

  group('reading', () {
    test('a sent message can be read', () {
      final read = message()
          .sentAtInstant(written)
          .readAtInstant(written.add(const Duration(minutes: 1)));

      expect(read.isRead, isTrue);
    });

    test('a queued message cannot, and asking is not an error', () {
      final asked = message().readAtInstant(written);

      expect(asked.isRead, isFalse);
      expect(asked.isQueued, isTrue);
    });

    test('the first read wins', () {
      final read = message().sentAtInstant(written).readAtInstant(written);

      final again = read.readAtInstant(written.add(const Duration(hours: 2)));

      expect(again.readAt, read.readAt);
    });

    test('two messages with one identifier are the same message', () {
      expect(message(), message().sentAtInstant(written));
    });
  });

  group('a stored message', () {
    test('cannot have been read without having been sent', () {
      final refused = Message.stored(
        id: (MessageId.parse('MSG-1') as Success<MessageId, MessagingFailure>)
            .value,
        thread: ThreadId.aboutShipment(parcel),
        author: dispatcher,
        body: 'impossible',
        writtenAt: written,
        sentAt: null,
        readAt: written,
      );

      expect(refused, isA<Failed<Message, MessagingFailure>>());
    });
  });

  group('ThreadId', () {
    test('a shipment thread is derived from the shipment', () {
      expect(ThreadId.aboutShipment(parcel).value, 'shipment:SHP-42');
      expect(ThreadId.aboutShipment(parcel).isAboutShipment, isTrue);
    });

    test('two devices deriving the same thread agree', () {
      expect(ThreadId.aboutShipment(parcel), ThreadId.aboutShipment(parcel));
    });

    test('a direct thread is derived from the actor identifier', () {
      expect(ThreadId.withActor('courier-7').value, 'courier:courier-7');
      expect(ThreadId.withActor('courier-7').isAboutShipment, isFalse);
    });

    test('parse round-trips what the factories produce', () {
      for (final thread in [
        ThreadId.aboutShipment(parcel),
        ThreadId.withActor('courier-7'),
      ]) {
        expect(
          (ThreadId.parse(thread.value) as Success<ThreadId, MessagingFailure>)
              .value,
          thread,
        );
      }
    });

    test('refuses an identifier that names neither', () {
      expect(
        ThreadId.parse('team:ops'),
        isA<Failed<ThreadId, MessagingFailure>>(),
      );
    });

    test('refuses one that names nothing', () {
      expect(
        ThreadId.parse('shipment:'),
        isA<Failed<ThreadId, MessagingFailure>>(),
      );
    });
  });

  group('MessageId', () {
    test('trims what it is given', () {
      expect(
        (MessageId.parse('  MSG-1  ') as Success<MessageId, MessagingFailure>)
            .value
            .value,
        'MSG-1',
      );
    });

    test('refuses an empty identifier', () {
      expect(
        MessageId.parse('  '),
        isA<Failed<MessageId, MessagingFailure>>(),
      );
    });
  });
}
