import 'package:sync_api/sync_api.dart';

/// A `SyncCommand` for tests, belonging to no feature.
///
/// Every test that needs something to queue would otherwise reach for a real
/// command — `CompleteDeliveryCommand`, say — and that import is exactly the
/// edge scenario 3 exists to forbid: `sync_testing` may not depend on
/// `delivery_application`, and would not want to if it could, because a fake
/// that broke when delivery's use cases were refactored is a fake nobody
/// trusts.
///
/// So the tests here queue work from a feature that does not exist. That is
/// not a limitation of the fixture; it is a demonstration that the queue never
/// needed to know.
final class TestSyncCommand implements SyncCommand {
  /// Creates a command with a routing key and a body.
  const TestSyncCommand({
    this.type = 'test.write',
    this.payload = '{"ok":true}',
  });

  @override
  final String type;

  @override
  final String payload;

  @override
  String toString() => 'TestSyncCommand($type)';
}
