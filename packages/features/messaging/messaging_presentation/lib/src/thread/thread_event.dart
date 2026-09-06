/// What can be asked of a thread.
sealed class ThreadEvent {
  const ThreadEvent();
}

/// Read the thread.
final class ThreadRequested extends ThreadEvent {
  /// Creates the event.
  const ThreadRequested();
}

/// Follow changes to this thread until the bloc closes.
final class ThreadWatched extends ThreadEvent {
  /// Creates the event.
  const ThreadWatched();
}

/// Write a message.
final class MessageSent extends ThreadEvent {
  /// Creates the event.
  const MessageSent(this.body);

  /// What the person typed. The one string in this workspace that is not a
  /// localisation key.
  final String body;
}

/// Record that the reader has seen the thread.
final class ThreadMarkedRead extends ThreadEvent {
  /// Creates the event.
  const ThreadMarkedRead();
}
