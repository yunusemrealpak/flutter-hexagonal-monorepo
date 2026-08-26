import 'package:incidents_api/incidents_api.dart';
import 'package:test/test.dart';

void main() {
  const policy = EscalationPolicy.standard();

  group('the standard policy', () {
    test('waits longer at the bottom than at the top', () {
      expect(
        policy.waitFor(IncidentSeverity.routine),
        greaterThan(policy.waitFor(IncidentSeverity.urgent)),
      );
      expect(
        policy.waitFor(IncidentSeverity.urgent),
        greaterThan(policy.waitFor(IncidentSeverity.critical)),
      );
    });

    test('raises an incident that has waited its full time', () {
      expect(
        policy.shouldEscalate(
          category: IncidentCategory.recipientUnavailable,
          severity: IncidentSeverity.routine,
          age: const Duration(hours: 4),
        ),
        isTrue,
      );
    });

    test('leaves one that has not', () {
      expect(
        policy.shouldEscalate(
          category: IncidentCategory.recipientUnavailable,
          severity: IncidentSeverity.routine,
          age: const Duration(hours: 3, minutes: 59),
        ),
        isFalse,
      );
    });

    test('never raises what is already at the top', () {
      expect(
        policy.shouldEscalate(
          category: IncidentCategory.fieldEmergency,
          severity: IncidentSeverity.critical,
          age: const Duration(days: 7),
        ),
        isFalse,
      );
    });
  });

  test('an operation can ship its own table', () {
    const impatient = EscalationPolicy(
      waits: {IncidentSeverity.routine: Duration(minutes: 1)},
    );

    expect(
      impatient.shouldEscalate(
        category: IncidentCategory.damage,
        severity: IncidentSeverity.routine,
        age: const Duration(minutes: 2),
      ),
      isTrue,
    );
  });

  test('every category has a starting severity', () {
    for (final category in IncidentCategory.values) {
      expect(IncidentSeverity.initialFor(category), isNotNull);
    }
  });
}
