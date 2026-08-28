/// Every string key this package asks an app to answer.
abstract final class MessagingStrings {
  /// The thread screen's title.
  static const String threadTitle = 'messaging.thread.title';

  /// Shown when a thread exists and nothing has been said in it.
  static const String threadEmpty = 'messaging.thread.empty';

  /// How many messages are written but not sent. Takes a `count` argument.
  static const String threadQueued = 'messaging.thread.queued';

  /// Written on this device, not yet accepted by the operation.
  static const String statusQueued = 'messaging.status.queued';

  /// Sent, and not read yet.
  static const String statusSent = 'messaging.status.sent';

  /// Read by the other side.
  static const String statusRead = 'messaging.status.read';

  /// The conversation could not be opened.
  static const String failureThreadUnavailable =
      'messaging.failure.threadUnavailable';

  /// The message is waiting for a connection.
  static const String failureDeferred = 'messaging.failure.deferred';

  /// The operation would not take the message.
  static const String failureRefused = 'messaging.failure.refused';

  /// The message is no longer there.
  static const String failureMissing = 'messaging.failure.missing';

  /// The message cannot be sent as written.
  static const String failureMalformed = 'messaging.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    threadTitle,
    threadEmpty,
    threadQueued,
    statusQueued,
    statusSent,
    statusRead,
    failureThreadUnavailable,
    failureDeferred,
    failureRefused,
    failureMissing,
    failureMalformed,
  ];
}
