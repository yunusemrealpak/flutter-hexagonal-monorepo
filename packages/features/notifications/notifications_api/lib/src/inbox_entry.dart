import 'package:core_kernel/core_kernel.dart';

import 'notification_id.dart';
import 'notification_kind.dart';
import 'notifications_failure.dart';

/// One alert, in one person's inbox.
///
/// An `Entity`, because an alert that has been read is still the same alert.
/// Equality is by [id] alone, which is what makes the at-least-once delivery
/// of push survivable: the same message arriving twice produces two equal
/// entries, and a `Set` or a store keyed by identifier collapses them without
/// anybody writing deduplication logic.
///
/// **It carries a key and arguments, not a sentence.** `assignment` plus
/// `{'shipment': 'SHP-42'}` is what an app's localisation turns into a line of
/// Turkish or English. A `String title` here would put one language in the
/// domain and make every alert untranslatable the moment it was stored.
///
/// **The read mark is an instant, not a boolean.** "Read" and "read at 14:02"
/// are the same fact stored twice if both are kept, and only one of them can
/// answer a dispatcher asking when somebody saw a route change.
final class InboxEntry extends Entity<NotificationId> {
  const InboxEntry._({
    required super.id,
    required this.kind,
    required this.subject,
    required this.arguments,
    required this.receivedAt,
    required this.readAt,
  });

  /// Records an alert that has just arrived.
  ///
  /// [receivedAt] comes from a `Clock`, never from `DateTime.now()` — rule A1,
  /// and the reason this factory takes it rather than reading it.
  ///
  /// [subject] is the localisation key. It is refused when empty, because an
  /// entry a screen cannot name is one a courier would see as a blank row and
  /// tap for ever.
  static Result<InboxEntry, NotificationsFailure> arriving({
    required NotificationId id,
    required NotificationKind kind,
    required String subject,
    required DateTime receivedAt,
    Map<String, String> arguments = const {},
  }) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedNotification(field: 'subject', reason: 'it is empty'),
      );
    }
    return Success(
      InboxEntry._(
        id: id,
        kind: kind,
        subject: trimmed,
        arguments: Map.unmodifiable(arguments),
        receivedAt: receivedAt.toUtc(),
        readAt: null,
      ),
    );
  }

  /// Rebuilds an entry that was already stored, read mark and all.
  ///
  /// Separate from [arriving] on purpose. An arriving alert is unread by
  /// definition and a stored one may be anything, so one factory taking a
  /// nullable `readAt` would let a caller construct an alert that arrived
  /// already read — a state the product has no way to produce.
  static Result<InboxEntry, NotificationsFailure> stored({
    required NotificationId id,
    required NotificationKind kind,
    required String subject,
    required DateTime receivedAt,
    required DateTime? readAt,
    Map<String, String> arguments = const {},
  }) {
    if (readAt != null && readAt.toUtc().isBefore(receivedAt.toUtc())) {
      return const Failed(
        MalformedNotification(
          field: 'readAt',
          reason: 'it is before the alert arrived',
        ),
      );
    }
    return arriving(
      id: id,
      kind: kind,
      subject: subject,
      receivedAt: receivedAt,
      arguments: arguments,
    ).map(
      (entry) => InboxEntry._(
        id: entry.id,
        kind: entry.kind,
        subject: entry.subject,
        arguments: entry.arguments,
        receivedAt: entry.receivedAt,
        readAt: readAt?.toUtc(),
      ),
    );
  }

  /// What the alert is about.
  final NotificationKind kind;

  /// The localisation key a screen renders.
  final String subject;

  /// What that key needs filling in with.
  ///
  /// Unmodifiable, so an entity handed to three screens cannot be changed by
  /// one of them.
  final Map<String, String> arguments;

  /// When the alert reached this device, in UTC.
  final DateTime receivedAt;

  /// When it was read, or `null` while it has not been.
  final DateTime? readAt;

  /// Whether it is still waiting to be seen.
  bool get isUnread => readAt == null;

  /// Marks the alert read at [instant].
  ///
  /// **Idempotent, and the first mark wins.** Two devices show the same inbox,
  /// and the second one to tap is reporting the same fact later; keeping its
  /// later instant would move a timestamp somebody had already been told.
  /// Refusing it outright would make an ordinary race look like a fault.
  InboxEntry readAtInstant(DateTime instant) => isUnread
      ? InboxEntry._(
          id: id,
          kind: kind,
          subject: subject,
          arguments: arguments,
          receivedAt: receivedAt,
          readAt: instant.toUtc(),
        )
      : this;
}
