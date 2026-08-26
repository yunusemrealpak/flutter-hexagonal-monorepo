import 'package:sync_api/sync_api.dart';

import 'test_sync_command.dart';

/// Builds an [OutboxEntry] in a state the queue could actually have produced.
///
/// The builder reaches a state by *calling the entity's own methods* rather
/// than by filling in fields. An entry with three attempts and no
/// `nextAttemptAt` is a shape no drain can create, and a test asserting
/// against one is asserting about a situation that never happens.
///
/// Every instant is a parameter with a fixed default. Nothing here calls
/// `DateTime.now()` — rule A1 — so a suite that builds a hundred entries still
/// produces the same hundred entries tomorrow.
final class OutboxEntryBuilder {
  /// Starts from freshly queued work.
  OutboxEntryBuilder();

  /// The instant every builder measures from, unless one is given.
  static final DateTime defaultQueuedAt = DateTime.utc(2026, 3, 14, 12);

  String _id = 'entry-1';
  SyncCommand _command = const TestSyncCommand();
  ConflictPolicy _policy = const ConflictPolicy.lastWriteWins();
  DateTime _queuedAt = defaultQueuedAt;
  final List<({DateTime at, Duration backoff})> _attempts = [];
  String? _blockedReason;

  /// Gives the entry an identifier.
  OutboxEntryBuilder withId(String id) => this.._id = id;

  /// Queues [command] instead of the default one.
  OutboxEntryBuilder of(SyncCommand command) => this.._command = command;

  /// Queues a command with this routing key and an arbitrary body.
  OutboxEntryBuilder ofType(String type) =>
      this.._command = TestSyncCommand(type: type);

  /// Chooses what happens if the server has moved on.
  OutboxEntryBuilder under(ConflictPolicy policy) => this.._policy = policy;

  /// Sets when the work was queued.
  OutboxEntryBuilder queuedAt(DateTime at) => this.._queuedAt = at;

  /// Records a failed attempt at [at], with the wait that followed it.
  OutboxEntryBuilder attempted({
    DateTime? at,
    Duration backoff = const Duration(seconds: 1),
  }) => this.._attempts.add((at: at ?? _queuedAt, backoff: backoff));

  /// Blocks the entry for a person.
  OutboxEntryBuilder blocked([String reason = 'needs a person']) =>
      this.._blockedReason = reason;

  /// Produces the entry.
  OutboxEntry build() {
    final id = OutboxEntryId.parse(_id).fold(
      (value) => value,
      (failure) => throw StateError('$failure'),
    );

    var entry = OutboxEntry.queued(
      id: id,
      command: _command,
      policy: _policy,
      at: _queuedAt,
    );
    for (final attempt in _attempts) {
      entry = entry.attempted(at: attempt.at, backoff: attempt.backoff);
    }

    final reason = _blockedReason;
    return reason == null ? entry : entry.blocked(reason);
  }
}
