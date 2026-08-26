import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_testing/messaging_testing.dart';
import 'package:test/test.dart';

void main() {
  // The kit this package publishes, run against the fake this package ships.
  // `messaging_core` runs the same kit against the key-value adapter, which is
  // the whole point of the kit existing in a package of its own.
  runMessageStoreContract(InMemoryMessageStore.new);

  group('InMemoryMessageStore', () {
    test('can be told to fail, so failure branches are testable', () async {
      final store = InMemoryMessageStore()
        ..failNextWith(const ThreadUnavailable());

      final read = await store.thread(MessagingFixtures.thread.value);

      expect(read, isA<Failed<List<Message>, MessagingFailure>>());
    });

    test('two queued failures fail two calls', () async {
      final store = InMemoryMessageStore()
        ..failNextWith(const ThreadUnavailable())
        ..failNextWith(const ThreadUnavailable());

      final first = await store.thread(MessagingFixtures.thread.value);
      final second = await store.put(MessagingFixtures.queued());

      expect(first, isA<Failed<List<Message>, MessagingFailure>>());
      expect(second, isA<Failed<void, MessagingFailure>>());
    });
  });

  group('FakeMessagingFacade', () {
    test('a send succeeds and the message is not queued by default', () async {
      final facade = FakeMessagingFacade();
      addTearDown(facade.dispose);

      final sent = await facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.courier,
        body: 'on my way',
      );

      expect(
        (sent as Success<Message, MessagingFailure>).value.isQueued,
        isFalse,
      );
    });

    test('offline leaves the message queued, and still succeeds', () async {
      final facade = FakeMessagingFacade()..offline = true;
      addTearDown(facade.dispose);

      final sent = await facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.courier,
        body: 'no signal here',
      );

      expect(
        (sent as Success<Message, MessagingFailure>).value.isQueued,
        isTrue,
      );
    });

    test('marking read touches only what somebody else wrote', () async {
      final facade = FakeMessagingFacade();
      addTearDown(facade.dispose);
      await facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.courier,
        body: 'mine',
      );
      await facade.send(
        thread: MessagingFixtures.thread,
        author: MessagingFixtures.dispatcher,
        body: 'theirs',
      );

      final read = await facade.markRead(
        thread: MessagingFixtures.thread,
        reader: MessagingFixtures.courier,
      );

      final messages = (read as Success<List<Message>, MessagingFailure>).value;
      expect(messages.firstWhere((m) => m.body == 'mine').isRead, isFalse);
      expect(messages.firstWhere((m) => m.body == 'theirs').isRead, isTrue);
    });
  });

  group('MessagingFixtures', () {
    test('a queued message has been written and not sent', () {
      expect(MessagingFixtures.queued().isQueued, isTrue);
    });

    test('a sent one has both instants, in order', () {
      final message = MessagingFixtures.sent();

      expect(message.isQueued, isFalse);
      expect(message.sentAt!.isAfter(message.writtenAt), isTrue);
    });
  });
}
