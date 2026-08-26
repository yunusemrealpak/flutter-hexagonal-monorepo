import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// Reads everything waiting for one person, newest first.
///
/// The ordering is applied here rather than trusted from the store. A store
/// that returns rows in insertion order and a store that returns them in
/// whatever order a database chose are both legal implementations of
/// `InboxStore`, and a screen that showed yesterday's assignment above this
/// morning's would be wrong in a way nobody would attribute to the adapter.
final class ReadInbox
    implements UseCase<String, Result<List<InboxEntry>, NotificationsFailure>> {
  /// Creates the use case.
  const ReadInbox({required this._inbox});

  final InboxStore _inbox;

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> call(
    String actorId,
  ) async {
    final read = await _inbox.entriesFor(actorId);

    return read.map(
      (entries) =>
          [...entries]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
    );
  }
}
