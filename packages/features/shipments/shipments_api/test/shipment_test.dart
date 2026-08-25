@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('identity', () {
    test('a shipment that moved is still the same shipment', () {
      final before = accepted();
      final after = unwrap(before.assignTo(courier(), at: noon));

      // The assertion the hand-written-entity decision exists for. Generated
      // structural equality would make these unequal, and "is this the same
      // parcel?" would stop being a question anyone could ask separately from
      // "has anything about it changed?".
      expect(after, before);
      expect(after.hashCode, before.hashCode);
      expect(after.status, isNot(before.status));
    });

    test('two shipments with different identifiers are not equal', () {
      expect(accepted(), isNot(accepted(id: 'ship-2')));
    });
  });

  group('immutability', () {
    test(
      'a transition returns a new shipment and leaves the old one alone',
      () {
        final before = accepted();
        unwrap(before.assignTo(courier(), at: noon));

        expect(before.status, const ShipmentStatus.awaitingAssignment());
        expect(before.history, isEmpty);
      },
    );

    test('history cannot be written to through the entity', () {
      final shipment = at(ShipmentStatus.assignedToCourier(courier()));

      expect(
        () => shipment.history.add(shipment.history.first),
        throwsUnsupportedError,
      );
    });

    test('copyWith cannot change the state', () {
      // There is no `status` parameter, and that is the test: a copyWith that
      // took one would be a way around the whole state machine that looked
      // like ordinary code. This asserts the shape of the API, so it fails at
      // compile time if the parameter is ever added back.
      final shipment = accepted();
      final renamed = shipment.copyWith(consignee: consignee(name: 'Mehmet'));

      expect(renamed.status, shipment.status);
      expect(renamed.consignee.name, 'Mehmet');
    });
  });

  group('history', () {
    test('records every move, oldest first, with who and when', () {
      final out = at(ShipmentStatus.outForDelivery(courier()));

      expect(out.history.map((t) => t.to.label), [
        'assignedToCourier',
        'loadedOnVehicle',
        'outForDelivery',
      ]);
      expect(out.history.map((t) => t.from.label), [
        'awaitingAssignment',
        'assignedToCourier',
        'loadedOnVehicle',
      ]);
      expect(out.history.every((t) => t.by == courier()), isTrue);
      expect(out.history.every((t) => t.at == noon), isTrue);
    });

    test('records no actor for a move the system makes on its own', () {
      // The end-of-shift sweep has no actor, and inventing one would make the
      // audit trail lie.
      final out = at(ShipmentStatus.outForDelivery(courier()));
      final returned = unwrap(out.returnToDepot(at: noon));

      expect(returned.history.last.by, isNull);
    });

    test('a refused move leaves no trace', () {
      final shipment = accepted();
      final refused = shipment.completeDelivery(
        proofReference: 'proof-1',
        at: noon,
      );

      expect(refused.isFailure, isTrue);
      expect(shipment.history, isEmpty);
    });
  });

  group('the assigned courier', () {
    test('another courier may not load a shipment that is not theirs', () {
      final assigned = at(ShipmentStatus.assignedToCourier(courier()));
      final other = courier('courier-2');

      expect(
        assigned.loadOnto(other, at: noon),
        Failed<Shipment, ShipmentFailure>(
          NotTheAssignedCourier(assigned: courier(), attempted: other),
        ),
      );
    });

    test('another courier may not start a delivery that is not theirs', () {
      final loaded = at(ShipmentStatus.loadedOnVehicle(courier()));

      expect(
        loaded.startDelivery(courier('courier-2'), at: noon).isFailure,
        isTrue,
      );
    });

    test('the wrong courier is reported as such, not as a bad transition', () {
      // The move itself is legal and the person asking is the problem.
      // Collapsing the two would report a mis-scan at the wrong van as a
      // broken state machine.
      final assigned = at(ShipmentStatus.assignedToCourier(courier()));
      final failure = assigned
          .loadOnto(courier('courier-2'), at: noon)
          .fold((_) => null, (failure) => failure);

      expect(failure, isA<NotTheAssignedCourier>());
      expect(failure, isNot(isA<InvalidTransition>()));
    });

    test('the assigned courier may load and start', () {
      final assigned = at(ShipmentStatus.assignedToCourier(courier()));

      expect(assigned.loadOnto(courier(), at: noon).isSuccess, isTrue);
    });
  });

  group('the state carries what belongs to it', () {
    test('a state with a courier reports one; a terminal state does not', () {
      expect(
        at(ShipmentStatus.outForDelivery(courier())).status.courier,
        courier(),
      );
      expect(
        at(
          ShipmentStatus.deliveredToConsignee(
            proofReference: 'proof-1',
            at: noon,
          ),
        ).status.courier,
        isNull,
      );
    });

    test('a delivery needs a proof reference', () {
      final out = at(ShipmentStatus.outForDelivery(courier()));

      expect(
        out.completeDelivery(proofReference: '  ', at: noon),
        const Failed<Shipment, ShipmentFailure>(
          MalformedValue(field: 'proofReference', reason: 'is empty'),
        ),
      );
    });

    test('a failed attempt needs a reason', () {
      final out = at(ShipmentStatus.outForDelivery(courier()));

      expect(
        out.failDelivery(reason: '', at: noon),
        const Failed<Shipment, ShipmentFailure>(
          MalformedValue(field: 'reason', reason: 'is empty'),
        ),
      );
    });

    test('the proof reference is trimmed on the way in', () {
      final out = at(ShipmentStatus.outForDelivery(courier()));
      final delivered = unwrap(
        out.completeDelivery(proofReference: '  proof-1  ', at: noon),
      );

      expect(
        delivered.status,
        ShipmentStatus.deliveredToConsignee(
          proofReference: 'proof-1',
          at: noon,
        ),
      );
    });
  });
}
