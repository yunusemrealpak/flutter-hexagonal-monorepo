import 'package:messaging_api/messaging_api.dart';

/// What the thread screen can be showing.
sealed class ThreadState {
  const ThreadState();
}

/// Nothing has been asked for yet.
final class ThreadIdle extends ThreadState {
  /// Creates the state.
  const ThreadIdle();
}

/// The thread is being read.
final class ThreadLoading extends ThreadState {
  /// Creates the state.
  const ThreadLoading();
}

/// The thread arrived.
///
/// [messages] carries the queued ones too, in the order they were written.
/// That is the whole point of this feature's queue being the store: a courier
/// sees what they wrote where they wrote it, greyed out until it goes, rather
/// than watching it disappear and reappear somewhere else in the list.
final class ThreadReady extends ThreadState {
  /// Creates the state.
  const ThreadReady(this.messages);

  /// The conversation, oldest first.
  final List<Message> messages;

  /// How many are still waiting for a connection.
  int get queued => messages.where((message) => message.isQueued).length;
}

/// The thread could not be read, or a message could not be written down.
final class ThreadFailed extends ThreadState {
  /// Creates the state.
  const ThreadFailed(this.failure);

  /// What went wrong, in messaging's own words.
  final MessagingFailure failure;
}
