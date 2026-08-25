@Tags(['widget'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/widgets.dart';
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
  _Facade(this._rows);

  final List<ShipmentSummary> _rows;

  /// Every assignment the board asked for.
  final List<(ShipmentId, ActorId)> assignments = [];

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier,
  ) async => Success(_rows);

  @override
  Future<Result<Shipment, ShipmentFailure>> assign({
    required ShipmentId id,
    required ActorId courier,
  }) async {
    assignments.add((id, courier));
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

  DispatcherBoardController controllerFor(Set<Permission> granted) =>
      DispatcherBoardController(
        shipments: _Facade(rows()),
        permissions: _Permissions(granted),
        session: _Session(dispatcher),
      );

  group('scenario 6: the action is offered only when the port allows it', () {
    testWidgets('the bulk-assign action is absent without the permission', (
      tester,
    ) async {
      final controller = controllerFor({Permission.viewAllShipments});
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DispatcherBoardScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // `textContaining('Assign')` would match the status label
      // "awaitingAssignment" on every row, and pass for the wrong reason the
      // day the button disappeared for an unrelated one.
      expect(find.textContaining('selected'), findsNothing);
      expect(find.text('Consignee 0'), findsOneWidget);
    });

    testWidgets('and present with it', (tester) async {
      final controller = controllerFor({
        Permission.viewAllShipments,
        Permission.assignShipment,
        Permission.bulkAssignShipments,
      });
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DispatcherBoardScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign 0 selected'), findsOneWidget);
    });
  });

  group('the controller enforces it too', () {
    test(
      'assignSelected refuses without the permission, without asking',
      () async {
        // A rule that lives only on a widget is a rule a keyboard shortcut, a
        // deep link and a test do not have.
        final facade = _Facade(rows());
        final controller = DispatcherBoardController(
          shipments: facade,
          permissions: _Permissions({Permission.viewAllShipments}),
          session: _Session(dispatcher),
        );
        addTearDown(controller.dispose);

        await controller.load();
        controller.toggle('ship-0');

        final result = await controller.assignSelected(dispatcher.actor.id);

        expect(result.isFailure, isTrue);
        expect(facade.assignments, isEmpty);
      },
    );

    test('assigns every ticked shipment when it is allowed', () async {
      final facade = _Facade(rows());
      final controller = DispatcherBoardController(
        shipments: facade,
        permissions: _Permissions({
          Permission.viewAllShipments,
          Permission.bulkAssignShipments,
        }),
        session: _Session(dispatcher),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller
        ..toggle('ship-0')
        ..toggle('ship-2');

      final assigned = await controller.assignSelected(dispatcher.actor.id);

      expect(assigned.fold((count) => count, (f) => -1), 2);
      expect(facade.assignments.map((a) => a.$1.value), ['ship-0', 'ship-2']);
    });

    test('toggling twice unticks', () async {
      final controller = controllerFor({Permission.viewAllShipments});
      addTearDown(controller.dispose);

      await controller.load();
      controller
        ..toggle('ship-1')
        ..toggle('ship-1');

      final state = controller.state as BoardReady;
      expect(state.selected, isEmpty);
    });
  });
}
