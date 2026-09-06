@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_presentation/incidents_presentation.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `PermissionChecker` a test can set, standing in for identity.
///
/// Four lines, and the same four as in `payments_presentation`,
/// `delivery_presentation` and `shipments_presentation_dispatcher`. That the
/// stand-in is identical in four features is what scenario 6 buys.
final class _Permissions implements PermissionChecker {
  _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}

/// An `IncidentsFacade` this test steers.
final class _Incidents implements IncidentsFacade {
  final List<Incident> incidents = [];

  /// Held open by a test that needs two calls to overlap.
  Completer<void>? gate;

  /// Set to fail the next call, whatever it is.
  IncidentsFailure? failWith;

  int reports = 0;

  @override
  Future<Result<Incident, IncidentsFailure>> report({
    required ActorId reportedBy,
    required IncidentCategory category,
    ShipmentId? shipmentId,
    String? note,
  }) async {
    await gate?.future;
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    reports++;
    final opened = Incident.opened(
      id:
          (IncidentId.parse('INC-$reports')
                  as Success<IncidentId, IncidentsFailure>)
              .value,
      category: category,
      openedAt: DateTime.utc(2026, 3, 4, 9),
      reportedBy: reportedBy,
      shipmentId: shipmentId,
      note: note,
    );
    if (opened case Failed(:final failure)) {
      return Failed(failure);
    }
    final incident = (opened as Success<Incident, IncidentsFailure>).value;
    incidents.add(incident);
    return Success(incident);
  }

  @override
  Future<Result<List<Incident>, IncidentsFailure>> open() async {
    final failure = _taken();
    return failure == null
        ? Success(incidents.where((i) => i.isOpen).toList())
        : Failed(failure);
  }

  @override
  Future<Result<List<Incident>, IncidentsFailure>> escalateOverdue() async =>
      const Success([]);

  @override
  Future<Result<Incident, IncidentsFailure>> resolve({
    required IncidentId id,
    required String outcome,
  }) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    final index = incidents.indexWhere((incident) => incident.id == id);
    if (index < 0) {
      return Failed(IncidentMissing(id.value));
    }
    final resolved = incidents[index].resolvedAtInstant(
      DateTime.utc(2026, 3, 4, 10),
      outcome,
    );
    if (resolved case Failed(:final failure)) {
      return Failed(failure);
    }
    incidents[index] = (resolved as Success<Incident, IncidentsFailure>).value;
    return resolved;
  }

  IncidentsFailure? _taken() {
    final failure = failWith;
    failWith = null;
    return failure;
  }
}

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

IncidentBoardBloc _bloc(
  _Incidents incidents, {
  Set<Permission> granted = const {Permission.reportIncident},
}) => IncidentBoardBloc(
  incidents: incidents,
  permissions: _Permissions(granted),
  actor: _courier,
);

/// The tree the screen needs, with the bloc **owned by the provider**.
///
/// Never a bloc the test closes itself: a widget test runs inside a fake-async
/// zone and `Bloc.close()` completes on microtasks scheduled there, so
/// awaiting it from the body or from `addTearDown` hangs with no failure and
/// no timeout.
Widget _screen(_Incidents incidents) => PeykTheme.wrap(
  child: BlocProvider<IncidentBoardBloc>(
    create: (_) => _bloc(incidents),
    child: const IncidentBoardScreen(),
  ),
);

/// Puts one open incident on the board.
///
/// Through the facade rather than through a bloc, and deliberately: a widget
/// test must not close a bloc, so a helper that built one would either leak it
/// or hang the test.
Future<void> _report(_Incidents incidents) => incidents.report(
  reportedBy: _courier,
  category: IncidentCategory.accessDenied,
);

void main() {
  late _Incidents incidents;

  setUp(() => incidents = _Incidents());

  testWidgets('a clear board says so rather than showing nothing', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(incidents));
    await tester.pumpAndSettle();

    expect(find.text(IncidentsStrings.boardClear), findsOneWidget);
  });

  testWidgets('an open incident is drawn with its category and severity', (
    tester,
  ) async {
    await _report(incidents);

    await tester.pumpWidget(_screen(incidents));
    await tester.pumpAndSettle();

    expect(
      find.text(IncidentsStrings.category(IncidentCategory.accessDenied)),
      findsOneWidget,
    );
    // Severity is a chip a dispatcher can see, not only a label a screen
    // reader can hear. That was the change phase 6 said it was waiting for:
    // severity is the thing read first, and a word only assistive technology
    // reaches is not read first by anybody.
    expect(
      find.text(IncidentsStrings.severity(IncidentSeverity.routine)),
      findsOneWidget,
    );
  });

  testWidgets('a failure is rendered as a sentence, not a type name', (
    tester,
  ) async {
    incidents.failWith = const IncidentLogUnavailable();

    await tester.pumpWidget(_screen(incidents));
    await tester.pumpAndSettle();

    expect(
      find.text(IncidentsStrings.failureLogUnavailable),
      findsOneWidget,
    );
  });

  test('an actor without the permission reports nothing', () async {
    final bloc = _bloc(incidents, granted: const {});
    addTearDown(bloc.close);

    bloc.add(const IncidentReported(category: IncidentCategory.accessDenied));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.canReport, isFalse);
    expect(incidents.reports, 0);
  });

  test('an actor with it does', () async {
    final bloc = _bloc(incidents);
    addTearDown(bloc.close);

    bloc.add(const IncidentReported(category: IncidentCategory.accessDenied));
    await bloc.stream.firstWhere((state) => state is BoardReady);

    expect(incidents.reports, 1);
    expect(bloc.state, isA<BoardReady>());
  });

  // A double tap on a slow connection would otherwise be two rows on a
  // dispatcher's board for one thing that happened once: IncidentsFacade
  // .report takes no idempotency key. Remove `droppable()` and this reports
  // two.
  test('a second report while the first is in flight is dropped', () async {
    incidents.gate = Completer<void>();
    final bloc = _bloc(incidents);
    addTearDown(bloc.close);

    bloc
      ..add(const IncidentReported(category: IncidentCategory.accessDenied))
      ..add(const IncidentReported(category: IncidentCategory.accessDenied));
    await Future<void>.delayed(Duration.zero);
    incidents.gate!.complete();
    await bloc.stream.firstWhere((state) => state is BoardReady);

    expect(incidents.reports, 1);
  });

  test('resolving refreshes the board rather than editing a row', () async {
    final bloc = _bloc(incidents);
    addTearDown(bloc.close);
    bloc.add(const IncidentReported(category: IncidentCategory.accessDenied));
    await bloc.stream.firstWhere((state) => state is BoardReady);
    final open = (bloc.state as BoardReady).incidents;

    bloc.add(IncidentResolved(open.single.id, 'redelivered'));
    await bloc.stream.firstWhere(
      (state) => state is BoardReady && state.incidents.isEmpty,
    );

    expect((bloc.state as BoardReady).incidents, isEmpty);
  });

  // The reason a resolve is `sequential()` rather than `droppable()`: every
  // one of these is a *different* incident being closed, so dropping the
  // second would leave a dispatcher working quickly down a board with every
  // other row silently still open.
  test('two resolves in a row both happen', () async {
    await _report(incidents);
    await incidents.report(
      reportedBy: _courier,
      category: IncidentCategory.addressNotFound,
    );
    final bloc = _bloc(incidents);
    addTearDown(bloc.close);
    bloc.add(const BoardRequested());
    await bloc.stream.firstWhere(
      (state) => state is BoardReady && state.incidents.length == 2,
    );
    final open = (bloc.state as BoardReady).incidents;

    bloc
      ..add(IncidentResolved(open.first.id, 'redelivered'))
      ..add(IncidentResolved(open.last.id, 'towed'));
    await bloc.stream.firstWhere(
      (state) => state is BoardReady && state.incidents.isEmpty,
    );

    expect((bloc.state as BoardReady).incidents, isEmpty);
  });

  test('a refused report leaves the failure on screen', () async {
    final bloc = _bloc(incidents);
    addTearDown(bloc.close);
    incidents.failWith = const IncidentLogUnavailable();

    bloc.add(const IncidentReported(category: IncidentCategory.accessDenied));
    await bloc.stream.firstWhere((state) => state is BoardFailed);

    expect(bloc.state, isA<BoardFailed>());
  });

  group('what IncidentsStrings.all covers', () {
    // Derived from the enums it labels, so a new category cannot ship showing
    // its own key on a dispatcher's board.
    test('every category and severity has a key in it', () {
      for (final category in IncidentCategory.values) {
        expect(
          IncidentsStrings.all,
          contains(IncidentsStrings.category(category)),
        );
      }
      for (final severity in IncidentSeverity.values) {
        expect(
          IncidentsStrings.all,
          contains(IncidentsStrings.severity(severity)),
        );
      }
    });

    test('every failure maps to a key in it', () {
      const failures = <IncidentsFailure>[
        IncidentLogUnavailable(),
        IncidentMissing('inc-1'),
        IncidentNotInState(attempted: 'resolve', state: 'closed'),
        MalformedIncident(field: 'category', reason: 'unreadable'),
      ];

      for (final failure in failures) {
        expect(
          IncidentsStrings.all,
          contains(IncidentBoardScreen.describe(failure)),
        );
      }
    });
  });

  test('a critical incident is drawn as danger, a routine one is not', () {
    // The mapping design_system cannot make: a component knows what danger
    // looks like, and only incidents knows that "critical" is one.
    expect(
      IncidentBoardScreen.intentOf(IncidentSeverity.critical),
      PeykIntent.danger,
    );
    expect(
      IncidentBoardScreen.intentOf(IncidentSeverity.routine),
      isNot(PeykIntent.danger),
    );
  });
}
