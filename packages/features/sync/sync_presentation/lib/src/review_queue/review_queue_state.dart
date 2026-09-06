import 'package:sync_api/sync_api.dart';

/// What the manual-review screen can be showing.
///
/// Sealed and hand-written, in a package that has no code generation at all.
/// A presentation package with four small state cases and no annotated type
/// gets no `build.yaml` and no `build_runner` dependency, which CLAUDE.md §7.6
/// calls the cheapest configuration rather than a missing one.
///
/// Four cases rather than one class with `isLoading`, `entries` and `failure`
/// on it. The flat shape lets a widget be handed a loading state that also has
/// entries and a failure, and the day two of those are set at once nobody can
/// say what should be on screen.
sealed class ReviewQueueState {
  const ReviewQueueState();
}

/// Nothing has been asked for yet.
final class ReviewIdle extends ReviewQueueState {
  /// Creates the state.
  const ReviewIdle();
}

/// The queue is being read.
final class ReviewLoading extends ReviewQueueState {
  /// Creates the state.
  const ReviewLoading();
}

/// The queue arrived.
///
/// [entries] may be empty, and that is a different thing from [ReviewFailed]:
/// "nothing needs you" is the state this screen is in most of the time, and
/// showing an error for it would send somebody looking for a problem that
/// does not exist.
final class ReviewReady extends ReviewQueueState {
  /// Creates the state.
  const ReviewReady(this.entries);

  /// The work the queue gave up on, oldest first.
  final List<OutboxEntry> entries;
}

/// The queue could not be read.
final class ReviewFailed extends ReviewQueueState {
  /// Creates the state.
  const ReviewFailed(this.failure);

  /// What went wrong, in sync's own words.
  ///
  /// A `SyncFailure`, not a `String`. Turning it into a message is this
  /// layer's job and it happens at the widget, where the locale is known;
  /// carrying a formatted string here would put English in a state object and
  /// make it untranslatable a phase later.
  final SyncFailure failure;
}
