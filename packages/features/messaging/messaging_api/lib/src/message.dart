import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'message_id.dart';
import 'messaging_failure.dart';
import 'thread_id.dart';

/// One message in one thread.
///
/// **Three instants, and each of them answers a different question.**
/// [writtenAt] is when somebody typed it, [sentAt] when the server took it,
/// [readAt] when the other side saw it. A message written in a tunnel has the
/// first and not the second, and a thread that sorted by `sentAt` would
/// reorder itself when the signal came back — putting a courier's question
/// after the answer to it.
///
/// A boolean `isSent` would collapse the first two into one fact and lose the
/// only thing anybody asks afterwards, which is how long the message sat.
final class Message extends Entity<MessageId> {
  const Message._({
    required super.id,
    required this.thread,
    required this.author,
    required this.body,
    required this.writtenAt,
    required this.sentAt,
    required this.readAt,
  });

  /// Records a message somebody has just written.
  ///
  /// [writtenAt] comes from a `Clock` — rule A1.
  ///
  /// An empty body is refused. A thread full of blank rows is what a phone in
  /// a pocket produces, and every one of them is a notification somebody has
  /// to open.
  static Result<Message, MessagingFailure> written({
    required MessageId id,
    required ThreadId thread,
    required ActorId author,
    required String body,
    required DateTime writtenAt,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedMessage(field: 'body', reason: 'it is empty'),
      );
    }

    return Success(
      Message._(
        id: id,
        thread: thread,
        author: author,
        body: trimmed,
        writtenAt: writtenAt.toUtc(),
        sentAt: null,
        readAt: null,
      ),
    );
  }

  /// Rebuilds a message that was already stored.
  static Result<Message, MessagingFailure> stored({
    required MessageId id,
    required ThreadId thread,
    required ActorId author,
    required String body,
    required DateTime writtenAt,
    required DateTime? sentAt,
    required DateTime? readAt,
  }) {
    if (readAt != null && sentAt == null) {
      return const Failed(
        MalformedMessage(
          field: 'readAt',
          reason: 'a message nobody sent cannot have been read',
        ),
      );
    }

    return written(
      id: id,
      thread: thread,
      author: author,
      body: body,
      writtenAt: writtenAt,
    ).map(
      (message) => Message._(
        id: message.id,
        thread: message.thread,
        author: message.author,
        body: message.body,
        writtenAt: message.writtenAt,
        sentAt: sentAt?.toUtc(),
        readAt: readAt?.toUtc(),
      ),
    );
  }

  /// Which conversation it belongs to.
  final ThreadId thread;

  /// Who wrote it.
  final ActorId author;

  /// What it says.
  final String body;

  /// When it was written, in UTC.
  final DateTime writtenAt;

  /// When the server took it, or `null` while it is still queued.
  final DateTime? sentAt;

  /// When the other side read it, or `null`.
  final DateTime? readAt;

  /// Whether it is still waiting for a connection.
  bool get isQueued => sentAt == null;

  /// Whether the other side has seen it.
  bool get isRead => readAt != null;

  /// Records that the server took the message at [instant].
  ///
  /// Idempotent, and the first acknowledgement wins. The queue resends after a
  /// timeout, so the second acknowledgement is the same fact arriving later —
  /// and moving the instant would make a message look slower than it was.
  Message sentAtInstant(DateTime instant) => isQueued
      ? Message._(
          id: id,
          thread: thread,
          author: author,
          body: body,
          writtenAt: writtenAt,
          sentAt: instant.toUtc(),
          readAt: readAt,
        )
      : this;

  /// Records that the other side read the message at [instant].
  ///
  /// A message nobody has sent cannot be read, and asking is not an error —
  /// a read receipt for a queued message is what arrives when two devices
  /// resynchronise in the wrong order.
  Message readAtInstant(DateTime instant) => isQueued || isRead
      ? this
      : Message._(
          id: id,
          thread: thread,
          author: author,
          body: body,
          writtenAt: writtenAt,
          sentAt: sentAt,
          readAt: instant.toUtc(),
        );
}
