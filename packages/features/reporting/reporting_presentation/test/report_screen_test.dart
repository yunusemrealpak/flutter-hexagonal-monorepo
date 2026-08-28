@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_presentation/reporting_presentation.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `PermissionChecker` a test can set, standing in for identity.
///
/// The same four lines as in `payments_presentation`, `delivery_presentation`,
/// `shipments_presentation_dispatcher` and `incidents_presentation`. Five
/// features, one stand-in — which is what scenario 6 buys.
final class _Permissions implements PermissionChecker {
  _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}

/// A `ReportingFacade` this test steers.
final class _Reporting implements ReportingFacade {
  int reads = 0;

  /// Set to fail the next call.
  ReportingFailure? failWith;

  /// What the next range answers with.
  List<OperationTally> days = const [];

  @override
  Future<Result<OperationTally, ReportingFailure>> tallyFor(
    ReportingDay day,
  ) async => Success(OperationTally.empty(day));

  @override
  Future<Result<List<OperationTally>, ReportingFailure>> range({
    required ReportingDay from,
    required ReportingDay to,
  }) async {
    reads++;
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      return Failed(failure);
    }
    return Success(days);
  }
}

ShipmentId _parcel(String raw) =>
    (ShipmentId.parse(raw) as Success<ShipmentId, ShipmentFailure>).value;

ReportingDay get _today => ReportingDay.of(DateTime.utc(2026, 3, 4));

OperationTally _day({
  required DateTime on,
  int delivered = 0,
  int failed = 0,
}) {
  var tally = OperationTally.empty(ReportingDay.of(on));
  for (var i = 0; i < delivered; i++) {
    tally = tally.recording(
      shipment: _parcel('SHP-D$i-${on.day}'),
      outcome: ShipmentOutcome.delivered,
    );
  }
  for (var i = 0; i < failed; i++) {
    tally = tally.recording(
      shipment: _parcel('SHP-F$i-${on.day}'),
      outcome: ShipmentOutcome.failed,
    );
  }
  return tally;
}

Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

void main() {
  late _Reporting reporting;

  setUp(() => reporting = _Reporting());

  ReportController controller({
    Set<Permission> granted = const {Permission.viewReports},
  }) {
    final built = ReportController(
      reporting: reporting,
      permissions: _Permissions(granted),
    );
    addTearDown(built.dispose);
    return built;
  }

  testWidgets('a dispatcher sees the totals and a rate per day', (
    tester,
  ) async {
    reporting.days = [
      _day(on: DateTime.utc(2026, 3, 3), delivered: 3, failed: 1),
      _day(on: DateTime.utc(2026, 3, 4), delivered: 1, failed: 1),
    ];
    final subject = controller();

    await tester.pumpWidget(_wrap(ReportScreen(controller: subject)));
    await subject.load(
      from: ReportingDay.of(DateTime.utc(2026, 3, 3)),
      to: _today,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('${ReportingStrings.total}(count=6)'),
      findsOneWidget,
    );
    expect(
      find.text('${ReportingStrings.delivered}(count=4)'),
      findsOneWidget,
    );
    // The rate crosses as a number, not as "75%". Where the sign goes and
    // whether there is a space before it are the app's questions.
    expect(
      find.text('${ReportingStrings.dayRate}(day=2026-03-03, rate=75)'),
      findsOneWidget,
    );
    expect(
      find.text('${ReportingStrings.dayRate}(day=2026-03-04, rate=50)'),
      findsOneWidget,
    );
  });

  testWidgets('an actor without the permission is told, and nothing is read', (
    tester,
  ) async {
    final subject = controller(granted: const {});

    await tester.pumpWidget(_wrap(ReportScreen(controller: subject)));
    await subject.load(from: _today, to: _today);
    await tester.pumpAndSettle();

    expect(find.text(ReportingStrings.forbidden), findsOneWidget);
    expect(reporting.reads, 0);
  });

  testWidgets('an inverted range is a sentence, not an empty board', (
    tester,
  ) async {
    reporting.failWith = const RangeInverted(
      from: '2026-03-06',
      to: '2026-03-02',
    );
    final subject = controller();

    await tester.pumpWidget(_wrap(ReportScreen(controller: subject)));
    await subject.load(from: _today, to: _today);
    await tester.pumpAndSettle();

    expect(
      find.text(ReportingStrings.failureRangeInverted),
      findsOneWidget,
    );
  });

  test('an empty range reads as zero rather than as forbidden', () async {
    final subject = controller();

    await subject.load(from: _today, to: _today);

    expect(subject.state, isA<ReportReady>());
    expect((subject.state as ReportReady).total, 0);
  });

  test('a rate is rendered in whole points', () {
    expect(ReportScreen.percent(0), 0);
    expect(ReportScreen.percent(2 / 3), 67);
    expect(ReportScreen.percent(1), 100);
  });

  group('how a rate is drawn', () {
    // The thresholds are reporting's, not the design system's. Eighty-five per
    // cent being the line between "fine" and "look at this" is an operational
    // fact about a courier network; a component library that knew it would be
    // a component library that had learned what a delivery is.
    test('a bad day is drawn as danger and a good one is not', () {
      expect(ReportScreen.intentOfRate(0.99), PeykIntent.success);
      expect(ReportScreen.intentOfRate(0.5), PeykIntent.danger);
    });

    test('the thresholds are ordered', () {
      const rates = [0.5, 0.75, 0.9, 0.99];
      final intents = rates.map(ReportScreen.intentOfRate).toList();

      expect(intents.toSet(), hasLength(rates.length));
    });
  });

  test('every failure maps to a key an app is asked to answer', () {
    const failures = <ReportingFailure>[
      TallyUnavailable(),
      RangeInverted(from: '2026-03-04', to: '2026-03-03'),
      MalformedTally(field: 'day', reason: 'unreadable'),
    ];

    for (final failure in failures) {
      expect(ReportingStrings.all, contains(ReportScreen.describe(failure)));
    }
  });
}
