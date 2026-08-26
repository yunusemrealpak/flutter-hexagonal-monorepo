import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the messaging ports.
sealed class MessagingFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const MessagingFailure();
}

/// The local thread store could not be read or written.
///
/// The one failure a courier actually sees, because everything else this
/// feature does offline succeeds locally and waits.
final class ThreadUnavailable extends MessagingFailure {
  /// Records that the store did not answer, with [detail] for the log.
  const ThreadUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'ThreadUnavailable(${detail ?? 'no detail'})';
}

/// The server could not be reached.
///
/// Its own case, and it is **not** an error a courier is shown: a message
/// written with no signal is queued, not lost. The case exists so that
/// whatever is draining the queue can tell "try again later" from "this will
/// never work".
final class DeliveryDeferred extends MessagingFailure {
  /// Records that the message could not be sent now.
  const DeliveryDeferred({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'DeliveryDeferred(${detail ?? 'no detail'})';
}

/// The server refused the message and always will.
///
/// A thread that was closed, a courier removed from the round. Distinct from
/// [DeliveryDeferred] because retrying this one for ever is how an outbox
/// fills up with work nobody will ever accept.
final class DeliveryRefused extends MessagingFailure {
  /// Records the refusal, with [reason] for a person to read.
  const DeliveryRefused({required this.reason});

  /// Why the server said no.
  final String reason;

  @override
  String toString() => 'DeliveryRefused($reason)';
}

/// There is no message under the identifier that was asked for.
final class MessageMissing extends MessagingFailure {
  /// Records that [id] is not in the thread.
  const MessageMissing(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'MessageMissing($id)';
}

/// A value a message carries was refused at construction.
final class MalformedMessage extends MessagingFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedMessage({required this.field, required this.reason});

  /// Which part refused its value.
  final String field;

  /// Why it was refused.
  final String reason;

  @override
  String toString() => 'MalformedMessage($field: $reason)';
}
