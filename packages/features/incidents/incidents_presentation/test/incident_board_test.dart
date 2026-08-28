@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
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

Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

IncidentBoardController _controller(
  _Incidents incidents, {
  Set<Permission> granted = const {Permission.reportIncident},
}) => IncidentBoardController(
  incidents: incidents,
  permissions: _Permissions(granted),
  actor: _courier,
);

void main() {
  late _Incidents incidents;

  setUp(() => incidents = _Incidents());

  testWidgets('a clear board says so rather than showing nothing', (
    tester,
  ) async {
    final controller = _controller(incidents);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(IncidentBoardScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text(IncidentsStrings.boardClear), findsOneWidget);
  });

  testWidgets('an open incident is drawn with its category and severity', (
    tester,
  ) async {
    final controller = _controller(incidents);
    addTearDown(controller.dispose);
    await controller.report(category: IncidentCategory.accessDenied);

    await tester.pumpWidget(
      _wrap(IncidentBoardScreen(controller: controller)),
    );
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
    final controller = _controller(incidents);
    addTearDown(controller.dispose);
    incidents.failWith = const IncidentLogUnavailable();

    await tester.pumpWidget(
      _wrap(IncidentBoardScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(IncidentsStrings.failureLogUnavailable),
      findsOneWidget,
    );
  });

  test('an actor without the permission reports nothing', () async {
    final controller = _controller(incidents, granted: const {});
    addTearDown(controller.dispose);

    await controller.report(category: IncidentCategory.accessDenied);

    expect(controller.canReport, isFalse);
    expect(incidents.reports, 0);
  });

  test('an actor with it does', () async {
    final controller = _controller(incidents);
    addTearDown(controller.dispose);

    await controller.report(category: IncidentCategory.accessDenied);

    expect(incidents.reports, 1);
    expect(controller.state, isA<BoardReady>());
  });

  test('resolving refreshes the board rather than editing a row', () async {
    final controller = _controller(incidents);
    addTearDown(controller.dispose);
    await controller.report(category: IncidentCategory.accessDenied);
    final open = (controller.state as BoardReady).incidents;

    await controller.resolve(open.single.id, 'redelivered');

    expect((controller.state as BoardReady).incidents, isEmpty);
  });

  test('a refused report leaves the failure on screen', () async {
    final controller = _controller(incidents);
    addTearDown(controller.dispose);
    incidents.failWith = const IncidentLogUnavailable();

    await controller.report(category: IncidentCategory.accessDenied);

    expect(controller.state, isA<BoardFailed>());
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
