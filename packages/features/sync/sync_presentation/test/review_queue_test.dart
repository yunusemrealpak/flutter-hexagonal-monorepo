@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_presentation/sync_presentation.dart';
import 'package:sync_testing/sync_testing.dart';

/// A `SyncFacade` this test steers.
///
/// A stand-in rather than the real coordinator, and it has to be: this package
/// may not depend on `sync_application`. What it can name is the port, which
/// is exactly the point — the screen works against a contract, and which
/// implementation ends up behind it is an app's decision.
final class _Facade implements SyncFacade {
  _Facade(this._queue);

  Result<List<OutboxEntry>, SyncFailure> _queue;

  final StreamController<SyncStatus> _statuses =
      StreamController<SyncStatus>.broadcast();

  /// The identifiers `retry` was called with, in order.
  final List<String> retried = [];

  /// Whether `retry` should refuse.
  SyncFailure? retryFailure;

  /// Replaces what the queue answers with from now on.
  ///
  /// A method rather than a setter, so that it reads as the test arranging a
  /// situation rather than as part of the port it is standing in for.
  // ignore: use_setters_to_change_properties
  void answersWith(Result<List<OutboxEntry>, SyncFailure> queue) =>
      _queue = queue;

  /// Pushes a status to whoever is watching.
  void emit(SyncStatus status) => _statuses.add(status);

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> awaitingReview() async =>
      _queue;

  @override
  Future<Result<OutboxEntry, SyncFailure>> retry(OutboxEntryId id) async {
    retried.add(id.value);
    final failure = retryFailure;
    if (failure != null) return Failed(failure);

    _queue = const Success([]);
    return Success(OutboxEntryBuilder().withId(id.value).build());
  }

  @override
  Stream<SyncStatus> statusChanges() => _statuses.stream;

  /// Every other method of the port, which this test does not use.
  ///
  /// A stub rather than two overrides that return a plausible value. What it
  /// says is "this test is about the review queue"; a call to anything else
  /// throws, which is louder than a silent default.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Future<void> close() => _statuses.close();
}

OutboxEntry _blocked(
  String id, {
  String reason = 'rejected: unknown shipment',
}) => OutboxEntryBuilder()
    .withId(id)
    .ofType('delivery.completeAttempt')
    .attempted()
    .blocked(reason)
    .build();

void main() {
  late _Facade facade;
  late ReviewQueueController controller;

  setUp(() {
    facade = _Facade(Success([_blocked('e-1')]));
    controller = ReviewQueueController(sync: facade);
  });

  tearDown(() async {
    controller.dispose();
    await facade.close();
  });

  group('ReviewQueueController', () {
    test('starts idle and asks for nothing', () {
      expect(controller.state, isA<ReviewIdle>());
    });

    test('reads the queue and reports what it found', () async {
      await controller.load();

      final state = controller.state;
      expect(state, isA<ReviewReady>());
      expect((state as ReviewReady).entries.single.id.value, 'e-1');
    });

    test('an empty queue is ready, not failed', () async {
      // The state this screen is in most of the time. Reporting it as an error
      // would send somebody looking for a problem that does not exist.
      facade.answersWith(const Success([]));

      await controller.load();

      expect((controller.state as ReviewReady).entries, isEmpty);
    });

    test('reports a queue it could not read', () async {
      facade.answersWith(const Failed(OutboxUnavailable(detail: 'locked')));

      await controller.load();

      expect(controller.state, isA<ReviewFailed>());
    });

    test('re-reads after a retry rather than removing the row', () async {
      // Two people can be looking at the same review queue. A list that
      // removed the row optimistically would disagree with the store the
      // moment the other person resolved something.
      await controller.load();

      await controller.retry(_blocked('e-1').id);

      expect(facade.retried, ['e-1']);
      expect((controller.state as ReviewReady).entries, isEmpty);
    });

    test('reports a retry the queue refused', () async {
      facade.retryFailure = const OutboxUnavailable();

      await controller.retry(_blocked('e-1').id);

      expect(controller.state, isA<ReviewFailed>());
    });

    test('follows the status without touching the list', () async {
      await controller.load();
      controller.watch();

      facade.emit(const SyncStatus.blocked(pending: 3, needingReview: 1));
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, isA<SyncBlocked>());
      expect(
        controller.state,
        isA<ReviewReady>(),
        reason: 'a status change must not redraw a list that has not changed',
      );
    });

    test('watching twice keeps one subscription', () async {
      controller
        ..watch()
        ..watch();

      var notifications = 0;
      controller.addListener(() => notifications++);
      facade.emit(const SyncStatus.draining(pending: 1));
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 1);
    });
  });

  group('SyncStatusBadge', () {
    test('asks for a different key for every state', () {
      // Five cases, five sentences — the whole reason SyncStatus is a union
      // rather than a count plus a boolean. "You are in a basement" and "the
      // server said no, we are trying again" send a courier to different
      // places.
      final keys = <SyncStatus>[
        const SyncStatus.idle(),
        const SyncStatus.draining(pending: 2),
        const SyncStatus.waitingForNetwork(pending: 2),
        SyncStatus.waitingToRetry(
          pending: 2,
          nextAttemptAt: DateTime.utc(2026, 3, 14, 12),
        ),
        const SyncStatus.blocked(pending: 2, needingReview: 1),
      ].map(SyncStatusBadge.describe).toList();

      expect(keys.toSet(), hasLength(5));
      expect(SyncStrings.all, containsAll(keys));
    });

    test('only the blocked queue is drawn as something wrong', () {
      // The mapping design_system deliberately cannot make: a component knows
      // what danger looks like, and only sync knows that "given up on" is one.
      expect(
        SyncStatusBadge.intentOf(
          const SyncStatus.blocked(
            pending: 2,
            needingReview: 1,
          ),
        ),
        PeykIntent.danger,
      );
      expect(
        SyncStatusBadge.intentOf(const SyncStatus.idle()),
        PeykIntent.success,
      );
    });

    test('an idle queue carries no count', () {
      // A status with no number is not a status with a zero in it.
      expect(
        SyncStatusBadge.argumentsFor(const SyncStatus.idle()),
        isEmpty,
      );
      expect(
        SyncStatusBadge.argumentsFor(const SyncStatus.draining(pending: 2)),
        {'count': 2},
      );
    });

    testWidgets('redraws when the queue moves', (tester) async {
      controller.watch();
      await tester.pumpWidget(
        PeykTheme.wrap(child: SyncStatusBadge(controller: controller)),
      );

      facade.emit(const SyncStatus.waitingForNetwork(pending: 4));
      // Twice: the first pump lets the broadcast stream deliver the event and
      // the controller notify, the second rebuilds the tree that was marked
      // dirty by it.
      await tester.pump();
      await tester.pump();

      expect(
        find.text('${SyncStrings.statusWaitingForNetwork}(count=4)'),
        findsOneWidget,
      );
    });
  });

  group('ReviewQueueScreen', () {
    testWidgets('shows what stopped and why, and never the payload', (
      tester,
    ) async {
      // Not a layout choice: this package depends on sync_api, which cannot
      // decode a payload. Showing "the delivery for shipment SHP-9" would mean
      // reaching into delivery_api, and sync would have learned a feature's
      // name.
      await tester.pumpWidget(
        PeykTheme.wrap(child: ReviewQueueScreen(controller: controller)),
      );
      await tester.pump();

      expect(find.text('delivery.completeAttempt'), findsOneWidget);
      expect(find.text('rejected: unknown shipment'), findsOneWidget);
      expect(
        find.text('${SyncStrings.attempts}(count=1)'),
        findsOneWidget,
      );
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('says nothing needs you when the queue is clear', (
      tester,
    ) async {
      facade.answersWith(const Success([]));

      await tester.pumpWidget(
        PeykTheme.wrap(child: ReviewQueueScreen(controller: controller)),
      );
      await tester.pump();

      expect(find.text(SyncStrings.reviewEmpty), findsOneWidget);
    });

    testWidgets('asks the facade to retry when the row is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        PeykTheme.wrap(child: ReviewQueueScreen(controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('delivery.completeAttempt'));
      await tester.pump();

      expect(facade.retried, ['e-1']);
    });
  });

  group('SyncRoutes', () {
    test('guards the review screen behind a permission', () {
      // Scenario 6 in this feature: the route names a permission as a string,
      // and the app resolves it through identity's PermissionChecker. This
      // package never learns how identity decides.
      const module = SyncRoutes();

      expect(module.moduleName, 'sync');
      expect(module.routes.single.requiredPermission, isNotNull);
    });
  });
}
