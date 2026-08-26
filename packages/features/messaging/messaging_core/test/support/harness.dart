import 'package:core_testing/core_testing.dart';
import 'package:messaging_core/messaging_core.dart';
import 'package:messaging_testing/messaging_testing.dart';

/// Everything a messaging test needs, wired the way an app would wire it.
///
/// The store is the real key-value adapter over the in-memory `KeyValueStore`
/// fake, and the transport is the fake from `messaging_testing`. That is the
/// seam the constitution puts there: everything this package owns is exercised,
/// and only the two contracts somebody else declares are stood in for.
final class MessagingHarness {
  MessagingHarness() {
    store = KeyValueMessageStore(store: keyValue);
    final deliver = DeliverMessage(
      store: store,
      transport: transport,
      logger: logger,
    );
    facade = MessagingCoordinator(
      read: ReadThread(store: store),
      send: SendMessage(
        store: store,
        deliver: deliver,
        clock: clock,
        ids: ids,
      ),
      mark: MarkThreadRead(
        store: store,
        transport: transport,
        clock: clock,
      ),
      drain: DrainQueue(store: store, deliver: deliver),
    );
  }

  /// The store behind the threads.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The operation's end of the line.
  final FakeMessageTransport transport = FakeMessageTransport();

  /// Time, under the test's control.
  final FakeClock clock = FakeClock(MessagingFixtures.written);

  /// Identifiers, under the test's control.
  final FakeIdGenerator ids = FakeIdGenerator('MSG');

  /// Where a swallowed refusal is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The adapter under test.
  late final KeyValueMessageStore store;

  /// The facade under test.
  late final MessagingCoordinator facade;

  /// Releases what the harness started.
  Future<void> dispose() => facade.dispose();
}
