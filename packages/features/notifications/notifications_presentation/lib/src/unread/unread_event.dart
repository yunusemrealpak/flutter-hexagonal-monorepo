/// What can be asked of the unread count.
sealed class UnreadEvent {
  const UnreadEvent();
}

/// Follow the count until the bloc closes.
final class UnreadWatched extends UnreadEvent {
  /// Creates the event.
  const UnreadWatched();
}
