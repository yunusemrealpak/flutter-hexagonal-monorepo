@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// How many times the status stream was subscribed to, and left.
  int watchers = 0;
  int unwatched = 0;

  /// Whether two retries were ever in flight at once.
  bool overlapped = false;
  int _inFlight = 0;

  /// Whether `retry` should refuse.
  SyncFailure? retryFailure;

  /// Completed by the test to hold a retry open, when there is one.
  ///
  /// Without it every transformer produces the same trace: a fake that answers
  /// in the same microtask finishes one retry before the next event arrives,
  /// so `sequential()`, `droppable()` and `concurrent()` are indistinguishable
  /// and the test asserts nothing about the choice.
  Completer<void>? gate;

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
    _inFlight++;
    if (_inFlight > 1) overlapped = true;
    try {
      if (gate case final gate?) await gate.future;
      final failure = retryFailure;
      if (failure != null) return Failed(failure);

      _queue = const Success([]);
      return Success(OutboxEntryBuilder().withId(id.value).build());
    } finally {
      _inFlight--;
    }
  }

  /// A generator rather than the controller's stream, so that the test can see
  /// a subscription being *left* as well as opened. That is the difference
  /// `restartable()` makes, and nothing else on this port reveals it.
  @override
  Stream<SyncStatus> statusChanges() async* {
    watchers++;
    try {
      yield* _statuses.stream;
    } finally {
      unwatched++;
    }
  }

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

  setUp(() => facade = _Facade(Success([_blocked('e-1')])));

  tearDown(() async => facade.close());

  /// A bloc a plain test owns.
  ///
  /// Only a `test()` may do this. A widget test must never close a bloc
  /// itself: `Bloc.close()` completes on microtasks scheduled inside the
  /// fake-async zone, so awaiting it from a tear-down hangs with no failure
  /// and no timeout — which is why the trees below hand ownership to
  /// `BlocProvider`.
  ReviewQueueBloc queueBloc() {
    final bloc = ReviewQueueBloc(sync: facade);
    addTearDown(bloc.close);
    return bloc;
  }

  SyncStatusBloc statusBloc() {
    final bloc = SyncStatusBloc(sync: facade);
    addTearDown(bloc.close);
    return bloc;
  }

  /// Sends [event] and waits for its handler.
  Future<void> dispatch(ReviewQueueBloc bloc, ReviewQueueEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Widget screen() => PeykTheme.wrap(
    child: BlocProvider(
      create: (_) => ReviewQueueBloc(sync: facade),
      child: const ReviewQueueScreen(),
    ),
  );

  group('ReviewQueueBloc', () {
    test('starts idle and asks for nothing', () {
      expect(queueBloc().state, isA<ReviewIdle>());
      expect(facade.retried, isEmpty);
    });

    test('reads the queue and reports what it found', () async {
      final bloc = queueBloc();

      await dispatch(bloc, const ReviewRequested());

      expect(bloc.state, isA<ReviewReady>());
      expect((bloc.state as ReviewReady).entries.single.id.value, 'e-1');
    });

    test('an empty queue is ready, not failed', () async {
      // The state this screen is in most of the time. Reporting it as an error
      // would send somebody looking for a problem that does not exist.
      facade.answersWith(const Success([]));
      final bloc = queueBloc();

      await dispatch(bloc, const ReviewRequested());

      expect((bloc.state as ReviewReady).entries, isEmpty);
    });

    test('reports a queue it could not read', () async {
      facade.answersWith(const Failed(OutboxUnavailable(detail: 'locked')));
      final bloc = queueBloc();

      await dispatch(bloc, const ReviewRequested());

      expect(bloc.state, isA<ReviewFailed>());
    });

    test('re-reads after a retry rather than removing the row', () async {
      // Two people can be looking at the same review queue. A list that
      // removed the row optimistically would disagree with the store the
      // moment the other person resolved something.
      final bloc = queueBloc();
      await dispatch(bloc, const ReviewRequested());

      await dispatch(bloc, EntryRetried(_blocked('e-1').id));

      expect(facade.retried, ['e-1']);
      expect((bloc.state as ReviewReady).entries, isEmpty);
    });

    test('reports a retry the queue refused', () async {
      facade.retryFailure = const OutboxUnavailable();
      final bloc = queueBloc();

      await dispatch(bloc, EntryRetried(_blocked('e-1').id));

      expect(bloc.state, isA<ReviewFailed>());
    });

    test('two resolved entries both go back, and never at once', () async {
      // Two entries a person resolved are two different things that must both
      // happen — `droppable()` would silently lose the second — and each is
      // followed by a re-read, so they must not overlap either: under
      // `concurrent()` the older read can answer last and put back a row the
      // newer one already saw resolved.
      //
      // Re-run with `droppable()` and only `e-1` is retried; with
      // `concurrent()` the two overlap.
      final bloc = queueBloc();
      await dispatch(bloc, const ReviewRequested());

      final gate = Completer<void>();
      facade.gate = gate;
      addTearDown(() => gate.isCompleted ? null : gate.complete());
      bloc
        ..add(EntryRetried(_blocked('e-1').id))
        ..add(EntryRetried(_blocked('e-2').id));
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(facade.retried, ['e-1', 'e-2']);
      expect(facade.overlapped, isFalse);
    });
  });

  group('SyncStatusBloc', () {
    test('is right from the first frame', () {
      // `statusChanges` emits the current status on subscription, so there is
      // no idle case to model and nothing to show while the first one arrives.
      expect(statusBloc().state, isA<SyncIdle>());
    });

    test('follows the queue', () async {
      final bloc = statusBloc()..add(const SyncStatusWatched());
      await pumpEventQueue();

      facade.emit(const SyncStatus.blocked(pending: 3, needingReview: 1));
      await pumpEventQueue();

      expect(bloc.state, isA<SyncBlocked>());
    });

    test('watching twice leaves the first subscription behind', () async {
      // What `restartable()` buys, and the only thing that reveals it: the
      // hand-written version needed a nullable `StreamSubscription`, a `??=`
      // to stop a second `watch()` opening a second one, and a `dispose`
      // override. Re-run with the transformer removed and nothing is
      // cancelled — two subscriptions stay open for the life of the bloc.
      final bloc = statusBloc()..add(const SyncStatusWatched());
      await pumpEventQueue();

      bloc.add(const SyncStatusWatched());
      await pumpEventQueue();

      expect(facade.watchers, 2);
      expect(facade.unwatched, 1);
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
          const SyncStatus.blocked(pending: 2, needingReview: 1),
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
      expect(SyncStatusBadge.argumentsFor(const SyncStatus.idle()), isEmpty);
      expect(
        SyncStatusBadge.argumentsFor(const SyncStatus.draining(pending: 2)),
        {'count': 2},
      );
    });

    testWidgets('redraws when the queue moves', (tester) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: BlocProvider(
            create: (_) =>
                SyncStatusBloc(sync: facade)..add(const SyncStatusWatched()),
            child: const SyncStatusBadge(),
          ),
        ),
      );
      // Twice before the event and twice after: the bloc reaches the stream
      // through `emit.onEach`, so the subscription is one async gap away from
      // the frame that created it, and a broadcast stream drops what it is
      // handed before anyone is listening.
      await tester.pump();
      await tester.pump();

      facade.emit(const SyncStatus.waitingForNetwork(pending: 4));
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
      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text('delivery.completeAttempt'), findsOneWidget);
      expect(find.text('rejected: unknown shipment'), findsOneWidget);
      expect(find.text('${SyncStrings.attempts}(count=1)'), findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('says nothing needs you when the queue is clear', (
      tester,
    ) async {
      facade.answersWith(const Success([]));

      await tester.pumpWidget(screen());
      await tester.pump();

      expect(find.text(SyncStrings.reviewEmpty), findsOneWidget);
    });

    testWidgets('asks the facade to retry when the row is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
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
