import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_core/notifications_core.dart';
import 'package:push_messaging/push_messaging.dart';

/// Everything a notifications test needs, wired the way an app would wire it.
///
/// Two fakes, both of them shipped by the package that owns the contract they
/// stand in for: `InMemoryKeyValueStore` from `core_testing`, because
/// `KeyValueStore` is declared in `core_ports`, and `FakePushMessagingClient`
/// from `platform/push_messaging`, because `PushMessagingClient` is declared
/// there. That is §2.2's rule about where a fake lives, and it is why this
/// feature needs no `_testing` package of its own.
///
/// Everything between those two fakes is real: the adapters, the use cases and
/// the coordinator. A test that faked `InboxStore` would be testing the
/// coordinator and skipping the half of the package that turns an entry into a
/// stored row.
final class NotificationsHarness {
  NotificationsHarness() {
    final inbox = KeyValueInboxStore(store: keyValue);
    channel = PushAlertChannel(client: push);
    registry = KeyValueAlertRegistry(store: keyValue);
    final read = ReadInbox(inbox: inbox);
    facade = NotificationsCoordinator(
      read: read,
      mark: MarkAlertRead(inbox: inbox, clock: clock),
      record: RecordArrivingAlert(inbox: inbox, clock: clock, ids: ids),
      open: OpenAlerts(channel: channel, registry: registry),
      close: CloseAlerts(channel: channel, registry: registry),
      state: ReadAlertState(registry: registry, permissions: permissions),
      channel: channel,
      logger: logger,
    );
  }

  /// The store behind the inbox.
  final InMemoryKeyValueStore keyValue = InMemoryKeyValueStore();

  /// The push provider.
  final FakePushMessagingClient push = FakePushMessagingClient();

  /// Time, under the test's control.
  final FakeClock clock = FakeClock(DateTime.utc(2026, 3, 4, 9));

  /// Identifiers, under the test's control.
  final FakeIdGenerator ids = FakeIdGenerator('minted');

  /// Where a swallowed failure is looked for.
  final RecordingLogger logger = RecordingLogger();

  /// The operating system's answer about notifications, under the test's
  /// control. Starts at `notDetermined`, which is where every device starts.
  final FakePermissionRequester permissions = FakePermissionRequester();

  /// The adapter over the push provider.
  late final PushAlertChannel channel;

  /// What this device remembers about having opened alerts.
  late final KeyValueAlertRegistry registry;

  /// The facade under test.
  late final NotificationsCoordinator facade;

  /// The actor every test acts as.
  static final ActorId courier = actor('courier-7');

  /// Parses [id] into an actor, for the tests that need a second one.
  static ActorId actor(String id) =>
      (ActorId.parse(id) as Success<ActorId, IdentityFailure>).value;

  /// Delivers a push, as the provider would.
  void deliver({
    required String id,
    PushMessageKind kind = PushMessageKind.shipmentAssigned,
    Map<String, String> data = const {'shipment': 'SHP-42'},
  }) => push.deliver(
    PushMessage(id: id, kind: kind, data: data, sentAt: clock.now()),
  );

  /// Releases everything the harness started.
  Future<void> dispose() async {
    await facade.dispose();
    await push.dispose();
  }
}
