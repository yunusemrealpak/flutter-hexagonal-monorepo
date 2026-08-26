import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:test/test.dart';

import 'messaging_fixtures.dart';

/// The behaviour every `MessageStore` has to have.
///
/// This kit is why `messaging` has a `_testing` package at all: it is run
/// against the in-memory fake in this package's own tests and against the
/// key-value adapter in `messaging_core`, so the two cannot drift. A feature
/// whose fakes are consumed only by its own tests does not need one — section
/// 7 of CLAUDE.md — and this one is consumed by another package.
///
/// The assertions are ordered by what breaks first in practice. Ordering comes
/// before storage, because a store that sorts by insertion looks correct until
/// two devices synchronise; and `put` replacing rather than appending is the
/// one an implementation gets wrong by writing an obvious `add`.
///
/// [createStore] must return a fresh, empty store on every call.
void runMessageStoreContract(MessageStore Function() createStore) {
  group('MessageStore contract', () {
    late MessageStore store;

    setUp(() => store = createStore());

    test('a thread nobody has written to is empty, not missing', () async {
      final read = await store.thread(MessagingFixtures.thread.value);

      expect(_messages(read), isEmpty);
    });

    test('reads back what was written', () async {
      await store.put(MessagingFixtures.queued());

      final read = await store.thread(MessagingFixtures.thread.value);

      expect(_messages(read).single.body, 'Gate code, please');
    });

    test('keeps a thread oldest first, whatever order it arrived in', () async {
      await store.put(
        MessagingFixtures.queued(
          withId: 'MSG-2',
          body: 'second',
          at: MessagingFixtures.written.add(const Duration(minutes: 5)),
        ),
      );
      await store.put(MessagingFixtures.queued(body: 'first'));

      final read = await store.thread(MessagingFixtures.thread.value);

      expect(_messages(read).map((m) => m.body), ['first', 'second']);
    });

    test('put replaces the message with the same identifier', () async {
      await store.put(MessagingFixtures.queued());

      await store.put(MessagingFixtures.sent());
      final read = await store.thread(MessagingFixtures.thread.value);

      expect(_messages(read), hasLength(1));
      expect(_messages(read).single.isQueued, isFalse);
    });

    test('one thread does not leak into another', () async {
      await store.put(MessagingFixtures.queued());
      await store.put(
        MessagingFixtures.queued(
          withId: 'MSG-9',
          inThread: ThreadId.withActor('courier-7'),
        ),
      );

      final read = await store.thread(MessagingFixtures.thread.value);

      expect(_messages(read), hasLength(1));
    });

    test('the queue holds what has not been sent, oldest first', () async {
      await store.put(
        MessagingFixtures.queued(
          withId: 'MSG-2',
          at: MessagingFixtures.written.add(const Duration(minutes: 5)),
        ),
      );
      await store.put(MessagingFixtures.queued());
      await store.put(MessagingFixtures.sent(withId: 'MSG-3'));

      final queued = await store.queued();

      expect(_messages(queued).map((m) => m.id.value), ['MSG-1', 'MSG-2']);
    });

    test('a message leaves the queue when it is stored as sent', () async {
      await store.put(MessagingFixtures.queued());

      await store.put(MessagingFixtures.sent());
      final queued = await store.queued();

      expect(_messages(queued), isEmpty);
    });

    test('the queue spans threads, because a connection does', () async {
      await store.put(MessagingFixtures.queued());
      await store.put(
        MessagingFixtures.queued(
          withId: 'MSG-9',
          inThread: ThreadId.withActor('courier-7'),
          at: MessagingFixtures.written.add(const Duration(minutes: 1)),
        ),
      );

      final queued = await store.queued();

      expect(_messages(queued), hasLength(2));
    });
  });
}

/// Unwraps a read, failing the test if the store reported a failure.
///
/// Throwing is right here for the reason `MessagingFixtures` gives: a store
/// that fails inside its own contract kit is a broken implementation, not a
/// branch the kit should handle.
List<Message> _messages(Result<List<Message>, MessagingFailure> result) =>
    result.fold(
      (messages) => messages,
      (failure) => throw StateError('$failure'),
    );
