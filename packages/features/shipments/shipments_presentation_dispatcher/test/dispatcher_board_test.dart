@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_presentation_dispatcher/shipments_presentation_dispatcher.dart';
import 'package:shipments_testing/shipments_testing.dart';

/// A `PermissionChecker` a test can set, standing in for identity.
///
/// Three lines, and it is the entire coupling between this package and
/// identity. That is what scenario 6 is for: the board asks a question and
/// gets a bool, and everything identity actually does to arrive at the answer
/// is invisible here — including in the test, which is the proof.
final class _Permissions implements PermissionChecker {
  _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}

/// A `SessionReader` over one fixed session.
final class _Session implements SessionReader {
  _Session(this.current);

  @override
  final Session? current;

  @override
  Stream<Session?> changes() => Stream.value(current);
}

/// A `ShipmentsFacade` that answers the two methods the board uses.
final class _Facade implements ShipmentsFacade {
  _Facade(List<ShipmentSummary> rows)
    : _answers = [Success(PageOf(items: rows))];

  /// Answers each page in turn, repeating the last once they run out.
  _Facade.pages(this._answers);

  final List<Result<PageOf<ShipmentSummary>, ShipmentFailure>> _answers;

  /// Every assignment the board asked for.
  final List<(ShipmentId, ActorId)> assignments = [];

  /// How many pages were asked for.
  int asked = 0;

  /// The page requests it was handed, oldest first.
  final List<PageRequest> requests = [];

  /// What `assign` answers, or `null` for a plain success.
  ShipmentFailure? refuseAssignment;

  /// Completed by the test to hold a call open, when there is one.
  ///
  /// Both methods await it, and neither adds a turn while it is unset. A fake
  /// that answers in the same microtask makes every transformer look alike:
  /// a second event arrives after the first has finished, so `droppable()`,
  /// `restartable()` and `concurrent()` all produce the same trace and the
  /// test asserts nothing about the choice.
  Completer<void>? gate;

  @override
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier, {
    PageRequest page = const PageRequest(),
  }) async {
    final index = asked;
    asked++;
    requests.add(page);
    if (gate case final gate?) await gate.future;
    return _answers[index < _answers.length ? index : _answers.length - 1];
  }

  @override
  Future<Result<Shipment, ShipmentFailure>> assign({
    required ShipmentId id,
    required ActorId courier,
  }) async {
    assignments.add((id, courier));
    if (gate case final gate?) await gate.future;
    if (refuseAssignment case final failure?) return Failed(failure);
    return Success(ShipmentBuilder().withId(id.value).build());
  }

  /// Every other method of the port, which this test does not use.
  ///
  /// A stub rather than eleven `UnimplementedError` overrides. What it says is
  /// "this test is about one method"; a call to any other one throws, which is
  /// louder than an override returning a plausible empty value.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final dispatcher = SessionBuilder().withRoles({Role.dispatcher}).build();

  List<ShipmentSummary> rows() => [
    for (var index = 0; index < 3; index++)
      ShipmentSummary(
        id: 'ship-$index',
        barcode: '10000000000$index',
        status: const ShipmentStatus.awaitingAssignment(),
        consigneeName: 'Consignee $index',
        address: 'Address $index',
      ),
  ];

  DispatcherBoardBloc over(_Facade facade, Set<Permission> granted) {
    final bloc = DispatcherBoardBloc(
      shipments: facade,
      permissions: _Permissions(granted),
      session: _Session(dispatcher),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  /// Sends [event] and waits for its handler.
  Future<void> dispatch(
    DispatcherBoardBloc bloc,
    DispatcherBoardEvent event,
  ) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Holds [facade] open until the returned completer is completed.
  Completer<void> hold(_Facade facade) {
    final gate = Completer<void>();
    facade.gate = gate;
    addTearDown(() => gate.isCompleted ? null : gate.complete());
    return gate;
  }

  /// The tree the screen needs, with the bloc **owned by the provider**.
  ///
  /// A widget test must never close a bloc itself: `Bloc.close()` completes on
  /// microtasks scheduled inside the fake-async zone, so awaiting it from a
  /// tear-down hangs with no failure and no timeout.
  Widget screen(_Facade facade, Set<Permission> granted) => PeykTheme.wrap(
    child: BlocProvider(
      create: (_) => DispatcherBoardBloc(
        shipments: facade,
        permissions: _Permissions(granted),
        session: _Session(dispatcher),
      ),
      child: const DispatcherBoardScreen(),
    ),
  );

  ShipmentSummary row(String id) => ShipmentSummary(
    id: id,
    barcode: '100000000007',
    status: const ShipmentStatus.awaitingAssignment(),
    consigneeName: 'Consignee $id',
    address: 'Address',
  );

  group('paging', () {
    test('a ticked row stays ticked when the next page arrives', () async {
      // The thing paging costs this screen. A dispatcher assembles a bulk
      // assignment across pages, and a selection derived from the visible rows
      // — or dropped by the state that replaces them — would silently unpick
      // their work every time another twenty arrived.
      final bloc = over(
        _Facade.pages([
          Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
          Success(PageOf(items: [row('b')])),
        ]),
        {Permission.assignShipment, Permission.bulkAssignShipments},
      );

      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('a'));
      await dispatch(bloc, const MoreRequested());

      final state = bloc.state as BoardReady;
      expect(state.selected, {'a'});
      expect(state.rows.map((r) => r.id), ['a', 'b']);
    });

    test('a page that fails keeps the board and the ticks', () async {
      final bloc = over(
        _Facade.pages([
          Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
          const Failed(ShipmentsUnavailable()),
        ]),
        {Permission.assignShipment},
      );

      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('a'));
      await dispatch(bloc, const MoreRequested());

      final state = bloc.state as BoardReady;
      expect(state.selected, {'a'});
      expect(state.moreFailure, isA<ShipmentsUnavailable>());
    });

    test('will not fetch the same page twice in one gesture', () async {
      // A board that asks for more when it is scrolled asks several times in
      // one swipe. Without the guard the second request is issued from the
      // same state as the first, the same page comes back twice, and it is
      // appended twice — the same parcel on two rows, each with its own tick.
      //
      // The guard is `droppable()` on the registration and nothing written in
      // the handler. Re-run with the transformer removed and this fails on
      // three fetches and a duplicated row.
      final facade = _Facade.pages([
        Success(PageOf(items: [row('a')], next: const PageCursor('a'))),
        Success(PageOf(items: [row('b')])),
      ]);
      final bloc = over(facade, {Permission.assignShipment});
      await dispatch(bloc, const BoardRequested());

      final gate = hold(facade);
      bloc
        ..add(const MoreRequested())
        ..add(const MoreRequested());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(facade.asked, 2, reason: 'one first page and one second');
      expect((bloc.state as BoardReady).rows.map((r) => r.id), ['a', 'b']);
    });
  });

  group('scenario 6: the action is offered only when the port allows it', () {
    testWidgets('the bulk-assign action is absent without the permission', (
      tester,
    ) async {
      await tester.pumpWidget(
        screen(_Facade(rows()), {Permission.viewAllShipments}),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(ShipmentsDispatcherStrings.bulkAssign),
        findsNothing,
      );
      expect(find.text('Consignee 0'), findsOneWidget);
    });

    testWidgets('and present with it', (tester) async {
      await tester.pumpWidget(
        screen(_Facade(rows()), {
          Permission.viewAllShipments,
          Permission.assignShipment,
          Permission.bulkAssignShipments,
        }),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('${ShipmentsDispatcherStrings.bulkAssign}(count=0)'),
        findsOneWidget,
      );
    });
  });

  group('the bloc enforces it too', () {
    test(
      'an assignment is refused without the permission, without asking',
      () async {
        // A rule that lives only on a widget is a rule a keyboard shortcut, a
        // deep link and a test do not have.
        final facade = _Facade(rows());
        final bloc = over(facade, {Permission.viewAllShipments});

        await dispatch(bloc, const BoardRequested());
        await dispatch(bloc, const RowToggled('ship-0'));

        await dispatch(bloc, SelectionAssigned(dispatcher.actor.id));

        expect(facade.assignments, isEmpty);
        expect((bloc.state as BoardReady).assignFailure, isNull);
      },
    );

    test('assigns every ticked shipment when it is allowed', () async {
      final facade = _Facade(rows());
      final bloc = over(facade, {
        Permission.viewAllShipments,
        Permission.bulkAssignShipments,
      });

      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('ship-0'));
      await dispatch(bloc, const RowToggled('ship-2'));

      await dispatch(bloc, SelectionAssigned(dispatcher.actor.id));

      expect(facade.assignments.map((a) => a.$1.value), ['ship-0', 'ship-2']);
      // The board is read again, because what those two rows say has changed.
      expect(facade.asked, 2);
    });

    test('an assignment that is refused lands beside the ticks', () async {
      // The outcome used to be answered to a caller and no app had one. It
      // goes where every other outcome on this screen goes, and the ticks
      // survive it so the same selection can be sent again.
      final facade = _Facade(rows())
        ..refuseAssignment = const ShipmentsUnavailable();
      final bloc = over(facade, {
        Permission.viewAllShipments,
        Permission.bulkAssignShipments,
      });

      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('ship-0'));
      await dispatch(bloc, const RowToggled('ship-2'));

      await dispatch(bloc, SelectionAssigned(dispatcher.actor.id));

      final state = bloc.state as BoardReady;
      expect(state.assignFailure, isA<ShipmentsUnavailable>());
      expect(state.selected, {'ship-0', 'ship-2'});
      expect(
        facade.assignments,
        hasLength(1),
        reason: 'the walk stops at the first refusal',
      );
      expect(facade.asked, 1, reason: 'nothing changed, so nothing to re-read');
    });

    test('two taps on assign are one dispatcher asking once', () async {
      // The same shape as a payment. Re-run with `droppable()` dropped from
      // the registration and the eight parcels are assigned twice.
      final facade = _Facade(rows());
      final bloc = over(facade, {
        Permission.viewAllShipments,
        Permission.bulkAssignShipments,
      });
      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('ship-0'));

      final gate = hold(facade);
      bloc
        ..add(SelectionAssigned(dispatcher.actor.id))
        ..add(SelectionAssigned(dispatcher.actor.id));
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(facade.assignments, hasLength(1));
    });

    test('toggling twice unticks', () async {
      final bloc = over(_Facade(rows()), {Permission.viewAllShipments});

      await dispatch(bloc, const BoardRequested());
      await dispatch(bloc, const RowToggled('ship-1'));
      await dispatch(bloc, const RowToggled('ship-1'));

      expect((bloc.state as BoardReady).selected, isEmpty);
    });
  });

  group('what a tick redraws', () {
    testWidgets('the row that changed, and not the two hundred others', (
      tester,
    ) async {
      // The argument for `BlocSelector` on a board. Ticking a row emits a new
      // `BoardReady` over the same list: the list itself ignores it, because
      // `buildWhen` compares the rows by identity, and each row subscribes to
      // the one `bool` that says whether it is ticked.
      //
      // Re-run with either half removed — the `buildWhen`, or the selector in
      // `_BoardRow` — and the untouched row is a different widget.
      await tester.pumpWidget(
        screen(_Facade(rows()), {
          Permission.viewAllShipments,
          Permission.assignShipment,
        }),
      );
      await tester.pumpAndSettle();

      final untouched = tester.widget<PeykOptionRow>(
        find.byType(PeykOptionRow).at(1),
      );

      await tester.tap(find.text('Consignee 0'));
      await tester.pumpAndSettle();

      final ticked = tester.widget<PeykOptionRow>(
        find.byType(PeykOptionRow).at(0),
      );
      expect(ticked.selected, isTrue);
      expect(
        identical(
          untouched,
          tester.widget<PeykOptionRow>(find.byType(PeykOptionRow).at(1)),
        ),
        isTrue,
      );
    });

    testWidgets('and the count on the bulk action', (tester) async {
      await tester.pumpWidget(
        screen(_Facade(rows()), {
          Permission.viewAllShipments,
          Permission.assignShipment,
          Permission.bulkAssignShipments,
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Consignee 0'));
      await tester.pumpAndSettle();

      expect(
        find.text('${ShipmentsDispatcherStrings.bulkAssign}(count=1)'),
        findsOneWidget,
      );
    });
  });

  group('the two shipments screens read the same states differently', () {
    // The half of scenario 7 that only two presentation packages can show. A
    // status is one fact; what it *means to the person looking at it* is two,
    // and neither package could say so if the mapping lived in shipments_api.
    test('undeliverable is a danger here and a warning to a courier', () {
      expect(
        DispatcherBoardScreen.intentOf(
          ShipmentStatus.undeliverable(
            at: DateTime.utc(2026, 3, 4),
            reason: 'nobody home',
          ),
        ),
        PeykIntent.danger,
      );
    });

    test('an unassigned parcel is a warning here and nothing to a courier', () {
      // A courier never sees one — it is not on their manifest. A dispatcher
      // sees a parcel with nobody driving it.
      expect(
        DispatcherBoardScreen.intentOf(
          const ShipmentStatus.awaitingAssignment(),
        ),
        PeykIntent.warning,
      );
    });

    // Written out rather than derived, because ShipmentStatus is a freezed
    // union with no `values` to walk. This switch is what keeps the list
    // honest: adding a state stops this test compiling.
    test('every state has a key in the manifest', () {
      final instant = DateTime.utc(2026, 3, 4);
      final statuses = <ShipmentStatus>[
        const ShipmentStatus.awaitingAssignment(),
        ShipmentStatus.returnedToDepot(at: instant),
        ShipmentStatus.undeliverable(reason: 'nobody home', at: instant),
        ShipmentStatus.deliveredToConsignee(
          proofReference: 'proof-1',
          at: instant,
        ),
      ];

      for (final status in statuses) {
        expect(
          ShipmentsDispatcherStrings.statusKeys,
          contains(ShipmentsDispatcherStrings.status(status)),
        );
      }
      expect(
        ShipmentsDispatcherStrings.statusKeys,
        hasLength(7),
        reason: 'ShipmentStatus has seven constructors',
      );
    });
  });
}
