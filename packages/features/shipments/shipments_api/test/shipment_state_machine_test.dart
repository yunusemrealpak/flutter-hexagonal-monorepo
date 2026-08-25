@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

/// The state machine is what this package exists to demonstrate, so it is
/// tested against the diagram rather than against the implementation: the
/// legal moves are listed once, every other pair is asserted to be refused,
/// and the two are checked to cover the whole matrix. A test that only walked
/// the happy path would keep passing after somebody added an edge.
void main() {
  group('the happy path', () {
    test('walks created -> assigned -> loaded -> out -> delivered', () {
      final delivered = unwrap(
        unwrap(
          unwrap(
            unwrap(
              accepted().assignTo(courier(), at: noon),
            ).loadOnto(courier(), at: noon),
          ).startDelivery(courier(), at: noon),
        ).completeDelivery(proofReference: 'proof-1', at: noon),
      );

      expect(
        delivered.status,
        ShipmentStatus.deliveredToConsignee(
          proofReference: 'proof-1',
          at: noon,
        ),
      );
      expect(delivered.history, hasLength(4));
      expect(delivered.status.isTerminal, isTrue);
    });

    test('a new shipment starts awaiting assignment, with no history', () {
      final shipment = accepted();

      expect(shipment.status, const ShipmentStatus.awaitingAssignment());
      expect(shipment.history, isEmpty);
    });
  });

  group('the transition table', () {
    /// The diagram, written out. Every pair not in here must be refused.
    const legal = <(String, String)>{
      ('awaitingAssignment', 'assignedToCourier'),
      ('assignedToCourier', 'loadedOnVehicle'),
      ('loadedOnVehicle', 'outForDelivery'),
      ('outForDelivery', 'deliveredToConsignee'),
      ('outForDelivery', 'undeliverable'),
      ('outForDelivery', 'returnedToDepot'),
    };

    /// Attempts the move [to] on a shipment standing in [from].
    Result<Shipment, ShipmentFailure> move(
      ShipmentStatus from,
      ShipmentStatus to,
    ) {
      final shipment = at(from);
      return switch (to) {
        ShipmentAssignedToCourier(:final courier) => shipment.assignTo(
          courier,
          at: noon,
        ),
        ShipmentLoadedOnVehicle(:final courier) => shipment.loadOnto(
          courier,
          at: noon,
        ),
        ShipmentOutForDelivery(:final courier) => shipment.startDelivery(
          courier,
          at: noon,
        ),
        ShipmentDeliveredToConsignee(:final proofReference) =>
          shipment.completeDelivery(proofReference: proofReference, at: noon),
        ShipmentUndeliverable(:final reason) => shipment.failDelivery(
          reason: reason,
          at: noon,
        ),
        ShipmentReturnedToDepot() => shipment.returnToDepot(at: noon),
        // Unreachable. Nothing moves back to awaitingAssignment because no
        // transition method targets it — the machine says so at compile time
        // by not having one — and the loops below skip the column for that
        // reason. The arm returns a failure no expectation matches, so if the
        // guard ever disappears the matrix reports it instead of passing.
        //
        // Returning rather than throwing is not a style choice. `move`
        // declares a Result, and rule A5 forbids a second failure channel the
        // caller's type does not mention; arch_check catches it in test code
        // too, which is where the shortcut is most tempting.
        ShipmentAwaitingAssignment() => const Failed(
          MalformedValue(
            field: 'test',
            reason: 'an unreachable arm was reached',
          ),
        ),
      };
    }

    for (final from in everyState) {
      for (final to in everyState) {
        if (to is ShipmentAwaitingAssignment) continue;

        final pair = (from.label, to.label);
        final expected = legal.contains(pair);

        test(
          '${from.label} -> ${to.label} is '
          '${expected ? 'allowed' : 'refused'}',
          () {
            final result = move(from, to);

            if (expected) {
              expect(result.isSuccess, isTrue, reason: '$result');
              expect(unwrap(result).status, to);
            } else {
              expect(
                result,
                Failed<Shipment, ShipmentFailure>(
                  InvalidTransition(from: from.label, to: to.label),
                ),
              );
            }
          },
        );
      }
    }

    test('every legal pair in the table is reachable', () {
      // Guards the guard: if a state were renamed, `legal` would silently
      // describe pairs that no longer exist and the matrix above would go on
      // passing because it only ever asserts refusals.
      final labels = everyState.map((state) => state.label).toSet();
      for (final (from, to) in legal) {
        expect(labels, contains(from));
        expect(labels, contains(to));
      }
    });

    test('a terminal state accepts nothing at all', () {
      final terminals = everyState.where((state) => state.isTerminal);
      expect(terminals, hasLength(3));

      for (final terminal in terminals) {
        for (final target in everyState) {
          if (target is ShipmentAwaitingAssignment) continue;
          expect(
            move(terminal, target).isFailure,
            isTrue,
            reason: '${terminal.label} accepted ${target.label}',
          );
        }
      }
    });
  });

  group('the failure names both states', () {
    test('so that the message does not send anybody to a debugger', () {
      final failure = accepted()
          .completeDelivery(proofReference: 'proof-1', at: noon)
          .fold((_) => null, (failure) => failure);

      expect(
        failure,
        const InvalidTransition(
          from: 'awaitingAssignment',
          to: 'deliveredToConsignee',
        ),
      );
    });
  });
}
