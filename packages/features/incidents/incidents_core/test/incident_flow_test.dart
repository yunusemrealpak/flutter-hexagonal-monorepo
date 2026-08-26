import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late IncidentsHarness harness;

  setUp(() => harness = IncidentsHarness());
  tearDown(() => harness.dispose());

  group('reporting', () {
    test('records an incident somebody can be asked about', () async {
      final reported = await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.accessDenied,
        shipmentId: IncidentsHarness.parcel,
        note: 'gate locked',
      );

      final incident = IncidentsHarness.valueOf(reported);
      expect(incident.reportedBy, IncidentsHarness.courier);
      expect(incident.openedAt, harness.clock.now());
      expect(incident.severity, IncidentSeverity.routine);
      expect(
        IncidentsHarness.listOf(await harness.facade.open()),
        hasLength(1),
      );
    });

    test(
      'damage without a note is refused before anything is stored',
      () async {
        final reported = await harness.facade.report(
          reportedBy: IncidentsHarness.courier,
          category: IncidentCategory.damage,
          shipmentId: IncidentsHarness.parcel,
        );

        expect(IncidentsHarness.failureOf(reported), isA<MalformedIncident>());
        expect(IncidentsHarness.listOf(await harness.facade.open()), isEmpty);
      },
    );

    test('a locked store is a failure, not a lost incident', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      final reported = await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.accessDenied,
      );

      expect(
        IncidentsHarness.failureOf(reported),
        isA<IncidentLogUnavailable>(),
      );
    });
  });

  group('the open board', () {
    setUp(() async {
      await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.recipientUnavailable,
      );
      harness.clock.advance(const Duration(minutes: 10));
      await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.fieldEmergency,
      );
      harness.clock.advance(const Duration(minutes: 10));
      await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.damage,
        note: 'crushed corner',
      );
    });

    test('is worst first, then oldest', () async {
      final board = IncidentsHarness.listOf(await harness.facade.open());

      expect(
        board.map((incident) => incident.category),
        [
          IncidentCategory.fieldEmergency,
          IncidentCategory.damage,
          IncidentCategory.recipientUnavailable,
        ],
      );
    });

    test('a resolved incident leaves it', () async {
      final board = IncidentsHarness.listOf(await harness.facade.open());

      await harness.facade.resolve(
        id: board.first.id,
        outcome: 'courier collected, van towed',
      );

      final after = IncidentsHarness.listOf(await harness.facade.open());
      expect(after, hasLength(2));
    });

    test('resolving needs an account of what was done', () async {
      final board = IncidentsHarness.listOf(await harness.facade.open());

      final resolved = await harness.facade.resolve(
        id: board.first.id,
        outcome: '  ',
      );

      expect(IncidentsHarness.failureOf(resolved), isA<MalformedIncident>());
    });

    test('an incident that is not there is missing, not a fault', () async {
      final resolved = await harness.facade.resolve(
        id:
            (IncidentId.parse('INC-404')
                    as Success<IncidentId, IncidentsFailure>)
                .value,
        outcome: 'nothing',
      );

      expect(IncidentsHarness.failureOf(resolved), isA<IncidentMissing>());
    });
  });
}
