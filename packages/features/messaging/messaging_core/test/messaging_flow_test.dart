import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_testing/messaging_testing.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

List<Message> thread(Result<List<Message>, MessagingFailure> result) =>
    (result as Success<List<Message>, MessagingFailure>).value;

Message one(Result<Message, MessagingFailure> result) =>
    (result as Success<Message, MessagingFailure>).value;

void main() {
  late MessagingHarness harness;

  setUp(() => harness = MessagingHarness());
  tearDown(() => harness.dispose());

  Future<Result<Message, MessagingFailure>> write(String body) =>
      harness.facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.courier,
        body: body,
      );

  group('writing a message', () {
    test('is stored and sent when there is a connection', () async {
      harness.transport.accept(DateTime.utc(2026, 3, 4, 9, 15, 2));

      final sent = one(await write('Gate code, please'));

      expect(sent.isQueued, isFalse);
      expect(sent.sentAt, DateTime.utc(2026, 3, 4, 9, 15, 2));
    });

    test('succeeds and stays queued when there is not', () async {
      harness.transport.refuse(const DeliveryDeferred());

      final written = one(await write('no signal here'));

      expect(written.isQueued, isTrue);
      expect(
        thread(await harness.facade.read(MessagingFixtures.thread)),
        hasLength(1),
      );
    });

    test('fails only when the device cannot write it down', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      final written = await write('lost');

      expect(
        (written as Failed<Message, MessagingFailure>).failure,
        isA<ThreadUnavailable>(),
      );
    });

    test('an empty message is refused before anything is stored', () async {
      final written = await write('   ');

      expect(
        (written as Failed<Message, MessagingFailure>).failure,
        isA<MalformedMessage>(),
      );
      expect(harness.transport.sent, isEmpty);
    });

    test('a refusal is logged and the message is kept, not dropped', () async {
      harness.transport.refuse(const DeliveryRefused(reason: 'thread closed'));

      final written = one(await write('too late'));

      expect(written.isQueued, isTrue);
      expect(harness.logger.recordsAt(LogLevel.warning), hasLength(1));
    });

    test('the instant on a sent message is the server one', () async {
      harness.transport.accept(DateTime.utc(2026, 3, 4, 12));
      harness.clock.advance(const Duration(hours: 3));

      final sent = one(await write('whose clock?'));

      expect(sent.sentAt, DateTime.utc(2026, 3, 4, 12));
      expect(sent.writtenAt, isNot(sent.sentAt));
    });
  });

  group('draining the queue', () {
    Future<void> queueThree() async {
      for (final body in ['first', 'second', 'third']) {
        harness.transport.refuse(const DeliveryDeferred());
        await write(body);
        harness.clock.advance(const Duration(minutes: 1));
      }
    }

    test('sends everything waiting, oldest first', () async {
      await queueThree();

      final drained = thread(await harness.facade.drain());

      expect(drained.map((m) => m.body), ['first', 'second', 'third']);
    });

    test('stops at the first message that will not go', () async {
      await queueThree();
      harness.transport
        ..accept(DateTime.utc(2026, 3, 4, 10))
        ..refuse(const DeliveryDeferred());

      final drained = thread(await harness.facade.drain());

      expect(drained.map((m) => m.body), ['first']);
      expect(
        thread(
          await harness.facade.read(MessagingFixtures.thread),
        ).where((m) => m.isQueued).length,
        2,
      );
    });

    test('steps over a refusal so the rest are not blocked', () async {
      await queueThree();
      harness.transport
        ..refuse(const DeliveryRefused(reason: 'thread closed'))
        ..accept(DateTime.utc(2026, 3, 4, 10))
        ..accept(DateTime.utc(2026, 3, 4, 10, 1));

      final drained = thread(await harness.facade.drain());

      expect(drained.map((m) => m.body), ['second', 'third']);
    });

    test('a drained thread is announced once', () async {
      final announced = <ThreadId>[];
      harness.facade.changes().listen(announced.add);
      await queueThree();
      // Broadcast delivery is asynchronous, so the three announcements the
      // writes produced have to arrive before the list is cleared.
      await pumpEventQueue();
      announced.clear();

      await harness.facade.drain();
      await pumpEventQueue();

      expect(announced, [MessagingFixtures.thread]);
    });
  });

  group('read receipts', () {
    test('mark what the other side wrote and leave your own alone', () async {
      harness.transport
        ..accept(DateTime.utc(2026, 3, 4, 9, 16))
        ..accept(DateTime.utc(2026, 3, 4, 9, 17));
      await write('mine');
      await harness.facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.dispatcher,
        body: 'theirs',
      );

      final marked = thread(
        await harness.facade.markRead(
          thread: MessagingFixtures.thread,
          reader: MessagingFixtures.courier,
        ),
      );

      expect(marked.firstWhere((m) => m.body == 'mine').isRead, isFalse);
      expect(marked.firstWhere((m) => m.body == 'theirs').isRead, isTrue);
    });

    test('a queued message cannot be read, and that is not an error', () async {
      harness.transport.refuse(const DeliveryDeferred());
      await harness.facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.dispatcher,
        body: 'still waiting',
      );

      final marked = thread(
        await harness.facade.markRead(
          thread: MessagingFixtures.thread,
          reader: MessagingFixtures.courier,
        ),
      );

      expect(marked.single.isRead, isFalse);
    });

    test('one receipt is sent, for the newest message', () async {
      harness.transport
        ..accept(DateTime.utc(2026, 3, 4, 9, 16))
        ..accept(DateTime.utc(2026, 3, 4, 9, 17));
      await harness.facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.dispatcher,
        body: 'first',
      );
      harness.clock.advance(const Duration(minutes: 1));
      await harness.facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.dispatcher,
        body: 'second',
      );

      await harness.facade.markRead(
        thread: MessagingFixtures.thread,
        reader: MessagingFixtures.courier,
      );

      expect(harness.transport.acknowledged, hasLength(1));
      expect(harness.transport.acknowledged.single.body, 'second');
    });
  });
}
