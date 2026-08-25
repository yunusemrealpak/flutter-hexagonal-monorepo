import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'dispatcher_board_state.dart';

/// Drives the dispatcher's board.
///
/// This is scenario 6 of the architecture, and the whole of it is the
/// `PermissionChecker` in the constructor. The board asks *can this actor
/// bulk-assign?* and gets a `bool`. It does not know that identity has roles,
/// that a role carries a `PermissionSet`, that an actor can hold a personal
/// grant, or that any of it is decided by a class called `Actor`. If identity
/// replaced all of that tomorrow, this file would not change.
///
/// The port is also the smallest thing that answers the question. Identity
/// publishes `IdentityFacade` too, and handing the board that instead would
/// give a screen whose job is drawing a table the ability to sign the user
/// out.
final class DispatcherBoardController extends ChangeNotifier {
  /// Creates the controller over its ports.
  DispatcherBoardController({
    required this._shipments,
    required this._permissions,
    required this._session,
  });

  final ShipmentsFacade _shipments;
  final PermissionChecker _permissions;
  final SessionReader _session;

  DispatcherBoardState _state = const BoardIdle();

  /// What the screen should be showing.
  DispatcherBoardState get state => _state;

  /// Whether the bulk-assign action may be offered at all.
  ///
  /// Asked before the button is rendered rather than when it is pressed. A
  /// button that appears and then refuses is a button that teaches a
  /// dispatcher to distrust the screen; the server checks again anyway,
  /// because a permission check in a client is a courtesy and not a control.
  bool get canBulkAssign => _permissions.can(Permission.bulkAssignShipments);

  /// Whether a single assignment may be offered.
  ///
  /// A separate permission from [canBulkAssign], because the blast radius of
  /// the two differs by an order of magnitude. A supervisor who may reassign
  /// one parcel is not thereby allowed to reassign a depot.
  bool get canAssign => _permissions.can(Permission.assignShipment);

  /// Fetches the board.
  Future<void> load() async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;

    _emit(const BoardLoading());

    final board = await _shipments.manifestFor(actor);
    _emit(
      switch (board) {
        Success(value: final rows) => BoardReady(rows: rows),
        Failed(:final failure) => BoardFailed(failure),
      },
    );
  }

  /// Ticks or unticks one row.
  void toggle(String shipmentId) {
    final current = _state;
    if (current is! BoardReady) return;

    final selection = {...current.selected};
    if (!selection.remove(shipmentId)) selection.add(shipmentId);
    _emit(current.withSelection(selection));
  }

  /// Assigns every ticked shipment to [courier].
  ///
  /// Refuses without asking the operation when the actor may not bulk-assign.
  /// The check is here rather than only on the button because a controller is
  /// reachable from a keyboard shortcut, a deep link and a test, and a rule
  /// that lives on a widget is a rule those three do not have.
  Future<Result<int, ShipmentFailure>> assignSelected(ActorId courier) async {
    if (!canBulkAssign) {
      return const Failed(
        ShipmentsUnavailable(detail: 'not permitted to bulk-assign'),
      );
    }

    final current = _state;
    if (current is! BoardReady) return const Success(0);

    var assigned = 0;
    for (final id in current.selected) {
      // A switch rather than a fold with a throw in the failure branch. This
      // method declares a Result, and rule A5 forbids a second failure channel
      // the caller's type does not mention — arch_check catches it here too.
      switch (ShipmentId.parse(id)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(value: final shipmentId):
          final result = await _shipments.assign(
            id: shipmentId,
            courier: courier,
          );
          if (result case Failed(:final failure)) return Failed(failure);
          assigned++;
      }
    }

    await load();
    return Success(assigned);
  }

  void _emit(DispatcherBoardState next) {
    _state = next;
    notifyListeners();
  }
}
