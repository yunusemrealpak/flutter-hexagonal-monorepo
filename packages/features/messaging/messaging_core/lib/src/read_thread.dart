import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';

/// Reads one conversation, oldest first.
///
/// A thin use case over a port that already promises the order, and it stays a
/// use case for the reason `OpenAlerts` gives in notifications: the port
/// belongs to a use case, and keeping that true when there is nothing to
/// compose is what makes it obvious where the first rule goes.
final class ReadThread
    implements UseCase<ThreadId, Result<List<Message>, MessagingFailure>> {
  /// Creates the use case.
  const ReadThread({required this._store});

  final MessageStore _store;

  @override
  Future<Result<List<Message>, MessagingFailure>> call(ThreadId input) =>
      _store.thread(input.value);
}
