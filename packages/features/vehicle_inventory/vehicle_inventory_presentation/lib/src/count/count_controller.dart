import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'count_state.dart';

/// Drives the counting screen.
///
/// It holds one port — `VehicleInventoryFacade` — and no implementation.
/// Whether the manifest behind it came from the depot's backend or from
/// yesterday's cache is a composition-root decision this package cannot see.
final class CountController extends ChangeNotifier {
  /// Creates the controller for one courier.
  CountController({required this._inventory, required this._courier});

  final VehicleInventoryFacade _inventory;
  final ActorId _courier;

  CountState _state = const CountIdle();

  /// What the screen should be showing.
  CountState get state => _state;

  /// Picks up a count that was already open, or leaves the screen idle.
  ///
  /// Called before [start]. A phone that was killed mid-count leaves one
  /// behind, and a courier who had to start again would rescan a van they had
  /// already half counted — which is how a count ends up disagreeing with
  /// itself.
  Future<void> resume() async {
    _emit(const CountPreparing());

    final open = await _inventory.openCountFor(_courier);
    _emit(
      switch (open) {
        Success(value: final count?) => CountInProgress(count),
        Success() => const CountIdle(),
        Failed(:final failure) => CountFailed(failure),
      },
    );
  }

  /// Opens a count against the depot's manifest.
  Future<void> start(LoadDirection direction) async {
    _emit(const CountPreparing());
    _emit(
      _settled(
        await _inventory.startCount(
          courier: _courier,
          direction: direction,
        ),
      ),
    );
  }

  /// Records one scan.
  ///
  /// Ignored unless a count is in progress. A scan that arrived while the
  /// screen was preparing — a scanner fires whenever a trigger is pulled —
  /// has no count to go into, and inventing one would count a parcel against
  /// the wrong manifest.
  Future<void> scan(ShipmentId shipment) async {
    if (_state case CountInProgress(:final count)) {
      _emit(
        _settled(await _inventory.scan(count: count.id, shipment: shipment)),
      );
    }
  }

  /// Closes the count, discrepancy and all.
  Future<void> close() async {
    if (_state case CountInProgress(:final count)) {
      final closed = await _inventory.close(count.id);
      _emit(
        switch (closed) {
          Success(:final value) => CountClosedState(value),
          Failed(:final failure) => CountFailed(failure),
        },
      );
    }
  }

  CountState _settled(Result<LoadCount, VehicleInventoryFailure> result) =>
      switch (result) {
        Success(:final value) => CountInProgress(value),
        Failed(:final failure) => CountFailed(failure),
      };

  void _emit(CountState next) {
    _state = next;
    notifyListeners();
  }
}
