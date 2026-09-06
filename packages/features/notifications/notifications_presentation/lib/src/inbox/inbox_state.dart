import 'package:notifications_api/notifications_api.dart';

/// What the inbox screen can be showing.
///
/// Four cases rather than one class with `isLoading`, `entries` and `failure`
/// on it. The flat shape lets a widget be handed a loading state that also has
/// entries and a failure, and the day two of those are set at once nobody can
/// say what should be on screen.
sealed class InboxState {
  const InboxState();
}

/// Nothing has been asked for yet.
final class InboxIdle extends InboxState {
  /// Creates the state.
  const InboxIdle();
}

/// The inbox is being read.
final class InboxLoading extends InboxState {
  /// Creates the state.
  const InboxLoading();
}

/// The inbox arrived.
///
/// [entries] may be empty, and that is a different thing from [InboxFailed]:
/// an inbox with nothing in it is the state most inboxes are in, and showing
/// an error for it would send somebody looking for a problem that does not
/// exist.
final class InboxReady extends InboxState {
  /// Creates the state.
  const InboxReady(this.entries);

  /// What is waiting, newest first.
  final List<InboxEntry> entries;
}

/// The inbox could not be read.
final class InboxFailed extends InboxState {
  /// Creates the state.
  const InboxFailed(this.failure);

  /// What went wrong, in notifications' own words.
  final NotificationsFailure failure;
}
