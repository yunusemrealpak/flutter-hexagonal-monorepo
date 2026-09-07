@Tags(['widget'])
library;

import 'dart:async';

import 'package:app_courier/main.dart';
import 'package:delivery_presentation/delivery_presentation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_presentation/identity_presentation.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:routing_presentation/routing_presentation.dart';
import 'package:shipments_presentation_courier/shipments_presentation_courier.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_presentation/sync_presentation.dart';

import 'support/test_platform.dart';

/// The shell: four tabs, one stack each, and what happens to those stacks when
/// a session ends.
///
/// The first three tests need no widgets at all. A tab set is data, and the
/// interesting claims about it — every route is real, every root is openable,
/// nothing was left homeless — are claims about that data. That is the same
/// reason `CourierFlow` is a pure function: what could have been fourteen
/// `context.goNamed` calls nobody can check is instead one list a test reads.
void main() {
  late GetIt container;
  late _MutableSession sessions;

  setUp(() async {
    container = await configureCourier(testPlatform());
    sessions = _MutableSession(SessionBuilder().build());
    // Two registrations replaced rather than a second container built: the
    // graph underneath is the one this app composes, and a hand-built stand-in
    // would be a test of a different app. The grants are a courier's, plus the
    // two the delivery flow needs to reach a door.
    await container.unregister<SessionReader>();
    await container.unregister<PermissionChecker>();
    container
      ..registerSingleton<SessionReader>(sessions)
      ..registerSingleton<PermissionChecker>(
        const _Permissions({
          Permission.viewAssignedShipments,
          Permission.completeDelivery,
          Permission.collectPayment,
        }),
      );
  });

  tearDown(() => container.reset());

  group('the tab set', () {
    test('names only routes this app mounted', () {
      final router = buildCourierRouter(container);
      final declared = router.definitions.keys.toSet();

      for (final tab in courierTabs) {
        expect(
          declared,
          containsAll(tab.routes),
          reason: '${tab.label} points at a route no module declares',
        );
      }
    });

    // A tab root is opened by tapping a bar, and a tap carries no argument.
    // `/stops/:shipmentId/proof` can live inside a tab and can never be one.
    test('gives every tab a root that opens with no argument', () {
      final router = buildCourierRouter(container);

      for (final tab in courierTabs) {
        expect(
          router.definitions[tab.root]?.path,
          isNot(contains(':')),
          reason: '${tab.label} lands on a route that needs a parameter',
        );
      }
    });

    // The partition, asserted exactly rather than loosely, for the reason
    // `unmounted` is: a route added to a feature and given no tab is a screen
    // that exists, resolves and cannot be reached, and nothing else in the app
    // would report it.
    test(
      'every mounted route is in exactly one tab, or deliberately outside',
      () {
        final router = buildCourierRouter(container);
        final mounted = router.definitions.keys.toSet()
          ..removeAll(router.unmounted);

        expect(router.branchFaults, isEmpty);
        expect(
          mounted.difference(router.branched),
          courierRoutesOutsideShell,
          reason: 'a mounted route belongs in a tab or in the set outside it',
        );
      },
    );
  });

  group('the shell', () {
    /// Pumps the app, optionally against a queue the test steers.
    ///
    /// The default is the container's own facade, so that every test that has
    /// nothing to say about sync still runs against the graph the app
    /// composes. The two badge tests below pass their own, because what they
    /// assert is how many times it was subscribed to.
    Future<GoRouter> pumpShell(WidgetTester tester, {SyncFacade? sync}) async {
      final router = buildCourierRouter(container).build();
      await tester.pumpWidget(
        CourierApp(router: router, sync: sync ?? container<SyncFacade>()),
      );
      await tester.pumpAndSettle();
      return router;
    }

    Finder tab(String label) => find.descendant(
      of: find.byType(PeykNavigationBar),
      matching: find.text(label),
    );

    testWidgets('draws a bar with every tab, and lands on the first', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(find.byType(PeykNavigationBar), findsOneWidget);
      for (final label in ['Stops', 'Route', 'Inbox', 'More']) {
        expect(tab(label), findsOneWidget);
      }
      expect(find.byType(CourierManifestScreen), findsOneWidget);
    });

    testWidgets('a tap moves to another tab and the bar stays', (tester) async {
      await pumpShell(tester);

      await tester.tap(tab('Route'));
      await tester.pumpAndSettle();

      expect(find.byType(RouteScreen), findsOneWidget);
      expect(find.byType(PeykNavigationBar), findsOneWidget);
    });

    // What a `StatefulShellRoute` is for, and the reason the flow screens live
    // inside the stops tab rather than above it: a courier at a door who looks
    // at the map comes back to the door, not to the manifest.
    testWidgets('a tab keeps its own stack while another one is used', (
      tester,
    ) async {
      final router = await pumpShell(tester);

      router.goNamed('delivery.proof', pathParameters: {'shipmentId': 'SHP-1'});
      await tester.pumpAndSettle();
      expect(find.byType(ProofCaptureScreen), findsOneWidget);

      await tester.tap(tab('Route'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Stops'));
      await tester.pumpAndSettle();

      expect(find.byType(ProofCaptureScreen), findsOneWidget);
    });

    // The behaviour the bar forwards a repeat tap for. Without it there is no
    // way out of a stack for somebody who arrived by deep link and has nothing
    // to go back to.
    testWidgets('re-tapping the tab in force returns it to its root', (
      tester,
    ) async {
      final router = await pumpShell(tester);

      router.goNamed('delivery.proof', pathParameters: {'shipmentId': 'SHP-1'});
      await tester.pumpAndSettle();

      await tester.tap(tab('Stops'));
      await tester.pumpAndSettle();

      expect(find.byType(ProofCaptureScreen), findsNothing);
      expect(find.byType(CourierManifestScreen), findsOneWidget);
    });

    // The question this change had to answer rather than assume. A shell keeps
    // one navigator per tab; a session that ends has to leave none of them
    // holding the previous courier's parcels. It works because sign-in is
    // mounted outside the shell — leaving the shell disposes the branches —
    // and this test is what stops that from being an accident of wiring.
    testWidgets('signing out and back in leaves every tab at its root', (
      tester,
    ) async {
      final router = await pumpShell(tester);

      router.goNamed('delivery.proof', pathParameters: {'shipmentId': 'SHP-1'});
      await tester.pumpAndSettle();
      expect(find.byType(ProofCaptureScreen), findsOneWidget);

      sessions.end();
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(PeykNavigationBar), findsNothing);

      sessions.begin(SessionBuilder().build());
      await tester.pumpAndSettle();

      expect(find.byType(CourierManifestScreen), findsOneWidget);
      expect(find.byType(ProofCaptureScreen), findsNothing);
    });

    // The claim the placement makes, and the one nothing on screen could show.
    // The badge is drawn once, above the router, so all four tabs share a
    // single subscription to the queue. A provider on a route would open a
    // fresh one every time somebody arrived at a tab and abandon the previous
    // one on the way out — four watchers for one badge, all agreeing, and
    // three of them leaks. Re-run against a provider keyed per tab and the
    // count is 5 — one for the first frame and one for each tap.
    testWidgets('the queue badge is on every tab, and watches once for all', (
      tester,
    ) async {
      final sync = _Facade();
      addTearDown(sync.close);

      await pumpShell(tester, sync: sync);

      for (final label in ['Route', 'Inbox', 'More', 'Stops']) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        expect(
          find.byType(SyncStatusBadge),
          findsOneWidget,
          reason: 'the $label tab lost the badge',
        );
      }

      expect(sync.watchers, 1);
    });

    // That the strip is wired to the queue and not merely present. The idle
    // sentence is asserted first on purpose: the badge is drawn in every state
    // including the empty one, because a corner that is blank when everything
    // is sent and occupied when it is not is a corner nobody learns to read.
    testWidgets('the badge says what the queue is doing', (tester) async {
      final sync = _Facade();
      addTearDown(sync.close);

      await pumpShell(tester, sync: sync);
      expect(find.text('Everything is sent'), findsOneWidget);

      sync.emit(const SyncStatus.waitingForNetwork(pending: 4));
      await tester.pumpAndSettle();

      expect(find.text('4 waiting for signal'), findsOneWidget);
    });
  });
}

/// A queue this file steers, and counts the subscriptions to.
///
/// The count is what the placement test is about, so the stream is an `async*`
/// generator rather than the controller's own: subscribing to a broadcast
/// controller directly is invisible from the outside, and the number of
/// subscriptions is the entire difference between a provider above the router
/// and one on a route.
final class _Facade implements SyncFacade {
  final _statuses = StreamController<SyncStatus>.broadcast();

  /// How many times the status stream has been subscribed to.
  int watchers = 0;

  /// Pushes a status to whoever is watching.
  void emit(SyncStatus status) => _statuses.add(status);

  @override
  Stream<SyncStatus> statusChanges() async* {
    watchers++;
    yield* _statuses.stream;
  }

  /// Every other method of the port, which this file does not use.
  ///
  /// A stub rather than four overrides answering a plausible value: a call to
  /// anything else throws, which says "this test is about the badge" louder
  /// than a silent default would.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Future<void> close() => _statuses.close();
}

/// A session that can end and begin again, which is what this file is about.
///
/// The stream is a broadcast controller rather than `Stream.value`, because
/// `SessionRefresh` subscribes to it once and the test needs to push a second
/// event through the same subscription.
final class _MutableSession implements SessionReader {
  _MutableSession(this._session);

  final _changes = StreamController<Session?>.broadcast();
  Session? _session;

  @override
  Session? get current => _session;

  @override
  Stream<Session?> changes() => _changes.stream;

  void end() {
    _session = null;
    _changes.add(null);
  }

  void begin(Session session) {
    _session = session;
    _changes.add(session);
  }
}

final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
