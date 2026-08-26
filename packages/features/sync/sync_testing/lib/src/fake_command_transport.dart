import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

/// A `CommandTransportPort` that accepts envelopes and remembers them.
///
/// Behavioural rather than scripted. It advances a cursor on every accepted
/// envelope, and it de-duplicates by [SyncEnvelope.id] — which is what makes it
/// a useful stand-in for a server that honours idempotency, and what lets a
/// test assert that a retried entry produced one delivery rather than two.
///
/// It is also the adapter `app_harness` binds, so the fake and the real thing
/// are held to the same behaviour by `runCommandTransportContract`.
final class FakeCommandTransport implements CommandTransportPort {
  /// Creates the transport, starting from the given cursor.
  FakeCommandTransport({this._cursor = SyncCursor.beginning});

  final List<SyncEnvelope> _received = [];
  final Map<String, SyncCursor> _acknowledged = {};
  final List<SyncFailure> _queuedFailures = [];
  final Map<String, SyncFailure> _failuresByType = {};

  SyncCursor _cursor;
  int _issued = 0;

  /// Every envelope that arrived, including retries of the same entry.
  ///
  /// Retries are kept rather than collapsed: "how many times did this entry
  /// reach the server?" and "how many pieces of work landed?" are different
  /// questions, and an idempotency test needs both.
  List<SyncEnvelope> get received => List.unmodifiable(_received);

  /// The distinct pieces of work the server ended up holding.
  int get accepted => _acknowledged.length;

  /// Makes the next call — whichever envelope it carries — fail with
  /// [failure].
  void failNextWith(SyncFailure failure) => _queuedFailures.add(failure);

  /// Makes every envelope with this routing key fail with [failure].
  ///
  /// For the drain tests, where one entry has to keep failing while the ones
  /// behind it succeed. Queueing failures one at a time cannot express that,
  /// because the drain's order is what is under test.
  void failEveryTypeOf(String type, SyncFailure failure) =>
      _failuresByType[type] = failure;

  /// Stops failing envelopes with this routing key.
  void recover(String type) => _failuresByType.remove(type);

  @override
  Future<Result<SyncCursor, SyncFailure>> send(SyncEnvelope envelope) async {
    _received.add(envelope);

    final failure = _takeFailure() ?? _failuresByType[envelope.type];
    if (failure != null) return Failed(failure);

    // Idempotency, on the server's side of the boundary. An envelope whose id
    // has already been accepted is acknowledged with the cursor it got the
    // first time and produces no second piece of work — which is exactly what
    // a real server has to do, and what makes retrying a lost acknowledgement
    // safe.
    final already = _acknowledged[envelope.id.value];
    if (already != null) return Success(already);

    _cursor = SyncCursor('c-${++_issued}');
    _acknowledged[envelope.id.value] = _cursor;
    return Success(_cursor);
  }

  SyncFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
