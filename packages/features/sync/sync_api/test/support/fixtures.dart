import 'package:core_kernel/core_kernel.dart';
import 'package:sync_api/sync_api.dart';

/// A fixed instant every test in this package measures from.
///
/// A constant rather than a clock. Nothing here calls `DateTime.now()` — rule
/// A1 — and a queue whose rules take `at` as a parameter is one whose backoff
/// can be asserted on without waiting for it.
final noon = DateTime.utc(2026, 3, 14, 12);

/// Unwraps a [Result] in test setup, where a failure means the fixture itself
/// is wrong and the test has nothing left to say.
T unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));

/// An entry identifier.
OutboxEntryId entryId([String raw = 'entry-1']) =>
    unwrap(OutboxEntryId.parse(raw));

/// A command from a feature this package cannot name.
///
/// Which is the point: the tests here prove the queue works without ever
/// building a `CompleteDeliveryCommand`, because it could not import one.
final class TestCommand implements SyncCommand {
  /// Creates a command with a routing key and a body.
  const TestCommand({
    this.type = 'test.write',
    this.payload = '{"ok":true}',
  });

  @override
  final String type;

  @override
  final String payload;
}

/// A queued entry, at [noon] unless another instant is given.
OutboxEntry queued({
  String id = 'entry-1',
  SyncCommand command = const TestCommand(),
  ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  DateTime? at,
}) => OutboxEntry.queued(
  id: entryId(id),
  command: command,
  policy: policy,
  at: at ?? noon,
);
