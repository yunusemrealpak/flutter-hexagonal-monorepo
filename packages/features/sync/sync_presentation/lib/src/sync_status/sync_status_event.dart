/// What can happen to the queue indicator.
///
/// One event, and it stays a sealed hierarchy rather than becoming a bare
/// class: a bloc whose event type is not a union is one that cannot grow a
/// second event without every existing `on` registration changing shape.
sealed class SyncStatusEvent {
  const SyncStatusEvent();
}

/// Follow the queue for as long as the bloc is open.
final class SyncStatusWatched extends SyncStatusEvent {
  /// Creates the event.
  const SyncStatusWatched();
}
