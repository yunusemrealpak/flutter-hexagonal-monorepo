@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_presentation/vehicle_inventory_presentation.dart';

ShipmentId _parcel(String raw) =>
    (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

LoadCountId _countId(String raw) =>
    (LoadCountId.parse(raw) as Success<LoadCountId, VehicleInventoryFailure>)
        .value;

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// A `VehicleInventoryFacade` this test steers.
///
/// It really holds a `LoadCount` and really applies the entity's rules, so the
/// screen is tested against the arithmetic it will meet in an app rather than
/// against a script.
final class _Inventory implements VehicleInventoryFacade {
  LoadCount? current;

  /// Held open between a scan's read and its write.
  ///
  /// That is where the hazard lives: `scan` takes the count's *identifier*, so
  /// an adapter reads the row, applies the scan and writes it back. Two of
  /// those in flight at once both read the row as it was before either of
  /// them, and the second write loses the first scan.
  Completer<void>? gate;

  /// Set to fail the next call, whatever it is.
  VehicleInventoryFailure? failWith;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> startCount({
    required ActorId courier,
    required LoadDirection direction,
  }) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final opened = LoadCount.opened(
      id: _countId('CNT-1'),
      courier: courier,
      direction: direction,
      manifest: {_parcel('SHP-1'), _parcel('SHP-2')},
      startedAt: DateTime.utc(2026, 3, 4, 6, 30),
    );
    if (opened case Success(:final value)) {
      current = value;
    }
    return opened;
  }

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> scan({
    required LoadCountId count,
    required ShipmentId shipment,
  }) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final before = current!;
    await gate?.future;
    final scanned = before.scan(shipment);
    if (scanned case Success(:final value)) {
      current = value;
    }
    return scanned;
  }

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> close(
    LoadCountId count,
  ) async {
    final closed = current!.closedAtInstant(DateTime.utc(2026, 3, 4, 7));
    if (closed case Success(:final value)) {
      current = value;
    }
    return closed;
  }

  @override
  Future<Result<LoadCount?, VehicleInventoryFailure>> openCountFor(
    ActorId courier,
  ) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final open = current;
    return Success(open != null && open.isOpen ? open : null);
  }

  VehicleInventoryFailure? _taken() {
    final failure = failWith;
    failWith = null;
    return failure;
  }
}

void main() {
  late _Inventory inventory;

  setUp(() => inventory = _Inventory());

  CountBloc build() => CountBloc(inventory: inventory, courier: _courier);

  /// The tree the screen needs, with the bloc **owned by the provider**.
  ///
  /// A widget test must never close a bloc itself: `Bloc.close()` completes on
  /// microtasks scheduled inside the fake-async zone, so awaiting it from the
  /// body or from `addTearDown` hangs with no failure and no timeout.
  Widget screen() => PeykTheme.wrap(
    child: BlocProvider<CountBloc>(
      create: (_) => build(),
      child: const CountScreen(),
    ),
  );

  /// Sends [events] one at a time, letting each land before the next.
  ///
  /// Queueing them together would not work, and the reason is worth knowing:
  /// each `on<E>` registration listens to the event stream separately, so four
  /// events added in one turn are delivered to four handlers at once. A scan
  /// would arrive while the count was still being opened, find no count in
  /// progress and be ignored — which is exactly what the guard in
  /// `_onScanned` is for, and exactly not what the test meant to arrange.
  ///
  /// `pump` twice rather than `pumpAndSettle`: `CountPreparing` draws a
  /// spinner, and settling waits for an animation that is supposed to run
  /// forever.
  Future<void> dispatch(WidgetTester tester, List<CountEvent> events) async {
    final bloc = tester.element(find.byType(CountScreen)).read<CountBloc>();
    for (final event in events) {
      bloc.add(event);
      await tester.pump();
      await tester.pump();
    }
  }

  testWidgets('a fresh screen is idle', (tester) async {
    await tester.pumpWidget(screen());
    await dispatch(tester, const [CountResumed()]);

    expect(find.text(VehicleInventoryStrings.idle), findsOneWidget);
  });

  testWidgets('a started count shows how much of the van is counted', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await dispatch(tester, const [CountStarted(LoadDirection.loading)]);

    expect(
      find.text('${VehicleInventoryStrings.progress}(scanned=0, expected=2)'),
      findsOneWidget,
    );
    expect(
      find.text('${VehicleInventoryStrings.missing}(count=2)'),
      findsOneWidget,
    );
  });

  testWidgets('a scan moves the numbers', (tester) async {
    await tester.pumpWidget(screen());
    await dispatch(tester, [
      const CountStarted(LoadDirection.loading),
      ParcelScanned(_parcel('SHP-1')),
    ]);

    expect(
      find.text('${VehicleInventoryStrings.progress}(scanned=1, expected=2)'),
      findsOneWidget,
    );
    expect(
      find.text('${VehicleInventoryStrings.missing}(count=1)'),
      findsOneWidget,
    );
  });

  testWidgets('a parcel nobody expected is shown as well as counted', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await dispatch(tester, [
      const CountStarted(LoadDirection.loading),
      ParcelScanned(_parcel('SHP-9')),
    ]);

    expect(
      find.text('${VehicleInventoryStrings.unexpected}(count=1)'),
      findsOneWidget,
    );
  });

  testWidgets('a reconciled close says so', (tester) async {
    await tester.pumpWidget(screen());
    await dispatch(tester, [
      const CountStarted(LoadDirection.loading),
      ParcelScanned(_parcel('SHP-1')),
      ParcelScanned(_parcel('SHP-2')),
      const CountFinished(),
    ]);

    expect(
      find.text(VehicleInventoryStrings.reconciled),
      findsOneWidget,
    );
  });

  testWidgets('a failure is rendered as a sentence, not a type name', (
    tester,
  ) async {
    inventory.failWith = const ManifestUnavailable();

    await tester.pumpWidget(screen());
    await dispatch(tester, const [CountStarted(LoadDirection.loading)]);

    expect(
      find.text(VehicleInventoryStrings.failureManifestUnavailable),
      findsOneWidget,
    );
  });

  test('a scan before a count has started is ignored', () async {
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(ParcelScanned(_parcel('SHP-1')));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<CountIdle>());
    expect(inventory.current, isNull);
  });

  test('resume picks up a count that was left open', () async {
    final opened = build();
    addTearDown(opened.close);
    opened.add(const CountStarted(LoadDirection.loading));
    await opened.stream.firstWhere((state) => state is CountInProgress);

    final resumed = build();
    addTearDown(resumed.close);
    resumed.add(const CountResumed());
    await resumed.stream.firstWhere((state) => state is! CountPreparing);

    expect(resumed.state, isA<CountInProgress>());
  });

  // The transformer this feature exists to demonstrate. A scanner does not
  // wait: it fires whenever a trigger is pulled. `scan` sends the count's
  // identifier and the facade answers with the whole count, so two in flight
  // at once both read the count as it was before either of them and the second
  // answer overwrites the first — the parcel is scanned, the courier hears the
  // beep, and it is not in the count. Remove `sequential()` and this reports
  // one scan instead of two.
  test('two scans in the same instant both land', () async {
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const CountStarted(LoadDirection.loading));
    await bloc.stream.firstWhere((state) => state is CountInProgress);
    inventory.gate = Completer<void>();

    bloc
      ..add(ParcelScanned(_parcel('SHP-1')))
      ..add(ParcelScanned(_parcel('SHP-2')));
    await Future<void>.delayed(Duration.zero);
    inventory.gate!.complete();
    await bloc.stream.firstWhere(
      (state) => state is CountInProgress && state.count.scanned.length == 2,
    );

    expect((bloc.state as CountInProgress).count.scanned, hasLength(2));
  });

  group('what VehicleInventoryStrings.all covers', () {
    test('every failure maps to a key in it', () {
      const failures = <VehicleInventoryFailure>[
        ManifestUnavailable(),
        CountUnavailable(),
        CountMissing('lc-1'),
        CountClosed('lc-1'),
        MalformedCount(field: 'direction', reason: 'unreadable'),
      ];

      for (final failure in failures) {
        expect(
          VehicleInventoryStrings.all,
          contains(CountScreen.describe(failure)),
        );
      }
    });

    // A closed count is not reopened by asking again, and a count that is gone
    // stays gone. Both need a new count, which is a different button.
    test('a finished or missing count offers no retry', () {
      expect(CountScreen.canRetry(const CountClosed('lc-1')), isFalse);
      expect(CountScreen.canRetry(const CountMissing('lc-1')), isFalse);
      expect(CountScreen.canRetry(const ManifestUnavailable()), isTrue);
    });
  });
}
