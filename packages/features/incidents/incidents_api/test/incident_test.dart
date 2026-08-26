import 'package:core_kernel/core_kernel.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('opening an incident', () {
    test('starts open, unescalated, at the category severity', () {
      final incident = open(category: IncidentCategory.fieldEmergency);

      expect(incident.isOpen, isTrue);
      expect(incident.escalatedAt, isNull);
      expect(incident.severity, IncidentSeverity.critical);
    });

    test('damage needs a note, because it becomes a claim', () {
      final refused = Incident.opened(
        id: id('INC-2'),
        category: IncidentCategory.damage,
        openedAt: opened,
        reportedBy: courier,
        shipmentId: parcel,
      );

      expect(failureOf(refused), isA<MalformedIncident>());
    });

    test('every other category may be reported without one', () {
      for (final category in IncidentCategory.values) {
        if (category == IncidentCategory.damage) {
          continue;
        }
        expect(
          Incident.opened(
            id: id('INC-3'),
            category: category,
            openedAt: opened,
            reportedBy: courier,
          ),
          isA<Success<Incident, IncidentsFailure>>(),
          reason: '$category should not need a note',
        );
      }
    });

    test('an incident may concern no parcel at all', () {
      final incident = valueOf(
        Incident.opened(
          id: id('INC-4'),
          category: IncidentCategory.fieldEmergency,
          openedAt: opened,
          reportedBy: courier,
        ),
      );

      expect(incident.shipmentId, isNull);
    });
  });

  group('escalating', () {
    test('raises the severity one step and resets the age', () {
      final raised = valueOf(
        open().escalatedAtInstant(opened.add(const Duration(hours: 5))),
      );

      expect(raised.severity, IncidentSeverity.urgent);
      expect(raised.ageAt(opened.add(const Duration(hours: 5))), Duration.zero);
    });

    test('the highest severity stays there without failing', () {
      final critical = open(category: IncidentCategory.fieldEmergency);

      final raised = valueOf(critical.escalatedAtInstant(opened));

      expect(raised.severity, IncidentSeverity.critical);
      expect(raised, same(critical));
    });

    test('a resolved incident refuses to be escalated', () {
      final resolved = valueOf(open().resolvedAtInstant(opened, 'redelivered'));

      expect(
        failureOf(resolved.escalatedAtInstant(opened)),
        isA<IncidentNotInState>(),
      );
    });
  });

  group('resolving', () {
    test('records what was done', () {
      final resolved = valueOf(
        open().resolvedAtInstant(
          opened.add(const Duration(hours: 1)),
          '  redelivered next morning  ',
        ),
      );

      expect(resolved.isOpen, isFalse);
      expect(resolved.resolution, 'redelivered next morning');
    });

    test('refuses an empty account of what was done', () {
      expect(
        failureOf(open().resolvedAtInstant(opened, '   ')),
        isA<MalformedIncident>(),
      );
    });

    test('refuses a second closing', () {
      final resolved = valueOf(open().resolvedAtInstant(opened, 'done'));

      expect(
        failureOf(resolved.resolvedAtInstant(opened, 'done again')),
        isA<IncidentNotInState>(),
      );
    });
  });

  group('a stored incident', () {
    test('cannot have been resolved before it was opened', () {
      final refused = Incident.stored(
        id: id('INC-5'),
        category: IncidentCategory.accessDenied,
        severity: IncidentSeverity.routine,
        openedAt: opened,
        reportedBy: courier,
        escalatedAt: null,
        resolvedAt: opened.subtract(const Duration(minutes: 1)),
      );

      expect(failureOf(refused), isA<MalformedIncident>());
    });
  });
}
