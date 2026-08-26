import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'collection_state.dart';

/// Drives the screen a courier takes money on.
///
/// It holds three ports and no implementations: `PaymentsFacade` to read what
/// is owed and to collect it, `SessionReader` to know who is collecting, and
/// `PermissionChecker` to know whether they may.
///
/// **`canCollect` is scenario 6 in its third feature.** The screen asks
/// whether the signed-in actor holds `Permission.collectPayment` and learns
/// nothing else. `shipments_presentation_dispatcher` asks before bulk
/// assignment, `delivery_presentation` before recording a hand-over, and none
/// of the three knows anything about roles or grants.
///
/// **The amount is read, never typed.** It comes from `PaymentStatus`, so a
/// courier cannot collect a different number from the one the operation is
/// owed. A screen with a text field would be exactly where that difference got
/// in, and it would be indistinguishable from a typing mistake afterwards.
final class CollectionController extends ChangeNotifier {
  /// Creates the controller over its three ports.
  CollectionController({
    required this._payments,
    required this._session,
    required this._permissions,
  });

  final PaymentsFacade _payments;
  final SessionReader _session;
  final PermissionChecker _permissions;

  CollectionState _state = const CollectionIdle();

  /// What the screen should be showing.
  CollectionState get state => _state;

  /// Whether this actor may take money.
  ///
  /// Read on every build rather than cached. A permission can be revoked
  /// mid-shift, and a screen that answered from a value captured when it
  /// opened would keep offering an action the operation has taken away.
  bool get canCollect => _permissions.can(Permission.collectPayment);

  /// Reads what is owed on [shipment].
  Future<void> load(ShipmentId shipment) async {
    _emit(const CollectionLoading());

    final status = await _payments.paymentStatusOf(shipment);

    _emit(
      switch (status) {
        Success(value: Outstanding(:final amount)) => Owed(amount),
        // Settled, refunded and nothing-to-collect are one thing to a courier
        // standing at a door: there is nothing to do here.
        Success() => const NothingOwed(),
        Failed(:final failure) => CollectionFailed(failure),
      },
    );
  }

  /// Chooses how the money is being taken.
  void takeBy(PaymentMethod method) {
    if (_state case final Owed state) {
      _emit(state.copyWith(method: method));
    }
  }

  /// Takes the money.
  ///
  /// Refuses locally when the actor may not collect. The use case does not
  /// check permissions — identity is not one of its collaborators — so a
  /// screen that offered the action to somebody without the grant would be the
  /// last thing between them and a recorded payment.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this.
  Future<void> collect(ShipmentId shipment) async {
    if (_state case final Owed state) {
      if (!canCollect) return;

      final courier = _session.current?.actor.id;
      if (courier == null) return;

      final collected = await _payments.collectOnDelivery(
        shipment: shipment,
        courier: courier,
        amount: state.amount,
        method: state.method,
      );

      _emit(
        switch (collected) {
          Success(value: final attempt) => Collected(attempt),
          // The money is still owed and the courier is still at the door.
          // Dropping to a failure state would end a visit that has not
          // finished.
          Failed(:final failure) => state.copyWith(refusal: failure),
        },
      );
    }
  }

  void _emit(CollectionState next) {
    _state = next;
    notifyListeners();
  }
}
