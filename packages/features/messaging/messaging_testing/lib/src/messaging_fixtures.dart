import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// The values every messaging test starts from.
///
/// Static rather than a builder object, because a fixture that needs
/// configuring is a fixture the test has to be read twice to understand. Where
/// a test needs something different it passes the one parameter it cares
/// about.
///
/// Every accessor here unwraps a `Result` by throwing on failure. That is the
/// one place in the workspace where throwing is right: a fixture that cannot
/// be built is a broken test rather than a failure a caller should handle, and
/// the exception says so at the line that wrote it.
final class MessagingFixtures {
  const MessagingFixtures._();

  /// A fixed instant, so that no test needs a real clock.
  static final DateTime written = DateTime.utc(2026, 3, 4, 9, 15);

  /// The courier most fixtures are authored by.
  static final ActorId courier = _unwrap(ActorId.parse('courier-7'));

  /// The dispatcher on the other side of the thread.
  static final ActorId dispatcher = _unwrap(ActorId.parse('dispatch-1'));

  /// The parcel most threads are about.
  static final ShipmentId parcel = _unwrap(ShipmentId.parse('SHP-42'));

  /// The thread most fixtures live in.
  static ThreadId get thread => ThreadId.aboutShipment(parcel);

  /// Reads a message identifier.
  static MessageId id(String raw) => _unwrap(MessageId.parse(raw));

  /// A message that has been written and not yet sent.
  static Message queued({
    String withId = 'MSG-1',
    String body = 'Gate code, please',
    ActorId? author,
    ThreadId? inThread,
    DateTime? at,
  }) => _unwrap(
    Message.written(
      id: id(withId),
      thread: inThread ?? thread,
      author: author ?? courier,
      body: body,
      writtenAt: at ?? written,
    ),
  );

  /// A message the server has taken.
  static Message sent({
    String withId = 'MSG-1',
    String body = 'Gate code, please',
    ActorId? author,
    DateTime? at,
  }) => queued(
    withId: withId,
    body: body,
    author: author,
    at: at,
  ).sentAtInstant((at ?? written).add(const Duration(seconds: 2)));

  static T _unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
