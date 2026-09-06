import 'package:sync_api/sync_api.dart';

/// What can happen to the manual-review screen.
sealed class ReviewQueueEvent {
  const ReviewQueueEvent();
}

/// Read the work a person has to resolve.
final class ReviewRequested extends ReviewQueueEvent {
  /// Creates the event.
  const ReviewRequested();
}

/// Put one blocked entry back into the queue.
final class EntryRetried extends ReviewQueueEvent {
  /// Creates the event.
  const EntryRetried(this.id);

  /// Which entry a person resolved.
  final OutboxEntryId id;
}
