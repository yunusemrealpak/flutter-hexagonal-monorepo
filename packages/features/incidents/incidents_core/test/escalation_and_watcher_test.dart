import 'package:core_ports/core_ports.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_core/incidents_core.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  group('the escalation sweep', () {
    late IncidentsHarness harness;

    setUp(() async {
      harness = IncidentsHarness();
      await harness.facade.report(
        reportedBy: IncidentsHarness.courier,
        category: IncidentCategory.recipientUnavailable,
      );
    });
    tearDown(() => harness.dispose());

    test('raises nothing before the wait has passed', () async {
      harness.clock.advance(const Duration(hours: 3));

      final raised = IncidentsHarness.listOf(
        await harness.facade.escalateOverdue(),
      );

      expect(raised, isEmpty);
    });

    test('raises an incident that has waited its full time', () async {
      harness.clock.advance(const Duration(hours: 4));

      final raised = IncidentsHarness.listOf(
        await harness.facade.escalateOverdue(),
      );

      expect(raised.single.severity, IncidentSeverity.urgent);
    });

    test('running it again straight away raises nothing', () async {
      harness.clock.advance(const Duration(hours: 4));
      await harness.facade.escalateOverdue();

      final again = IncidentsHarness.listOf(
        await harness.facade.escalateOverdue(),
      );

      expect(again, isEmpty);
    });

    test(
      'the wait after an escalation is measured from the escalation',
      () async {
        harness.clock.advance(const Duration(hours: 4));
        await harness.facade.escalateOverdue();

        harness.clock.advance(const Duration(hours: 1));
        final again = IncidentsHarness.listOf(
          await harness.facade.escalateOverdue(),
        );

        expect(again.single.severity, IncidentSeverity.critical);
      },
    );

    test('an incident at the top stays there and reports nothing', () async {
      // Three sweeps, each after its own wait: routine to urgent, urgent to
      // critical, and then nothing. The waits have to pass between them
      // because escalation resets the age the sweep measures.
      harness.clock.advance(const Duration(hours: 4));
      await harness.facade.escalateOverdue();
      harness.clock.advance(const Duration(hours: 1));
      await harness.facade.escalateOverdue();
      harness.clock.advance(const Duration(days: 7));

      final again = IncidentsHarness.listOf(
        await harness.facade.escalateOverdue(),
      );

      expect(again, isEmpty);
      expect(
        IncidentsHarness.listOf(await harness.facade.open()).single.severity,
        IncidentSeverity.critical,
      );
    });

    test('a resolved incident is never raised', () async {
      final board = IncidentsHarness.listOf(await harness.facade.open());
      await harness.facade.resolve(id: board.single.id, outcome: 'redelivered');
      harness.clock.advance(const Duration(days: 1));

      expect(
        IncidentsHarness.listOf(await harness.facade.escalateOverdue()),
        isEmpty,
      );
    });
  });

  group('the shipment failure watcher', () {
    late IncidentsHarness harness;

    setUp(() {
      harness = IncidentsHarness();
      addTearDown(harness.watcher.start().cancel);
    });
    tearDown(() => harness.dispose());

    Future<void> publish(String reason) async {
      harness.events.publish(
        ShipmentFailed(
          shipmentId: IncidentsHarness.parcel,
          reason: reason,
          occurredAt: harness.clock.now(),
        ),
      );
      await pumpEventQueue();
    }

    test('opens an incident nobody reported', () async {
      await publish('recipient absent');

      final board = IncidentsHarness.listOf(await harness.facade.open());
      expect(board.single.reportedBy, isNull);
      expect(board.single.shipmentId, IncidentsHarness.parcel);
      expect(board.single.note, 'recipient absent');
    });

    test('classifies the phrases the operation actually writes', () async {
      await publish('parcel damaged in transit');

      final board = IncidentsHarness.listOf(await harness.facade.open());
      expect(board.single.category, IncidentCategory.damage);
      expect(board.single.severity, IncidentSeverity.urgent);
    });

    test(
      'a phrase it cannot place is unclassified, not the nearest guess',
      () async {
        await publish('the dog ate the consignment note');

        final board = IncidentsHarness.listOf(await harness.facade.open());
        expect(board.single.category, IncidentCategory.unclassified);
      },
    );

    test('a failure to record is logged and the watcher stays alive', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      await publish('recipient absent');
      await publish('gate locked');

      expect(harness.logger.recordsAt(LogLevel.warning), isNotEmpty);
      expect(
        IncidentsHarness.listOf(await harness.facade.open()),
        hasLength(1),
      );
    });

    test('shipments never learns that incidents exist', () {
      expect(harness.events.publishedOf<ShipmentFailed>(), isEmpty);
    });
  });

  group('ReasonClassifier', () {
    const classify = ReasonClassifier();

    test('every phrase in the table maps to its category', () {
      for (final phrase in ReasonClassifier.phrases.entries) {
        expect(classify('the courier wrote: ${phrase.key}'), phrase.value);
      }
    });

    test('matching ignores case for the phrases that survive folding', () {
      expect(classify('DAMAGED IN TRANSIT'), IncidentCategory.damage);
      expect(classify('Access Denied'), IncidentCategory.accessDenied);
    });

    test('an empty reason is unclassified', () {
      expect(classify(''), IncidentCategory.unclassified);
    });
  });
}
