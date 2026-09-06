import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'count_event.dart';
import 'count_state.dart';

/// Drives the counting screen.
///
/// It holds one port — `VehicleInventoryFacade` — and no implementation.
/// Whether the manifest behind it came from the depot's backend or from
/// yesterday's cache is a composition-root decision this package cannot see.
///
/// **This is the bloc where the transformers stop being a nicety.** A scanner
/// is not a person: it fires whenever a trigger is pulled, several times a
/// second, and it does not wait for the previous scan to be recorded.
///
/// - `sequential()` on [ParcelScanned]. Every scan is a *different* parcel, so
///   none may be dropped — and they must not overlap either. `scan` sends the
///   count's identifier and the facade answers with the whole count; two in
///   flight at once both read the count as it was before either of them, and
///   the second answer overwrites the first. The parcel is scanned, the
///   courier hears the beep, and it is not in the count. Queued is the only
///   correct answer here.
/// - `droppable()` on [CountStarted]. Two taps on *start* open two counts
///   against one manifest, and the second one has none of the first one's
///   scans.
/// - `droppable()` on [CountFinished], for the same reason one step later.
/// - `restartable()` on [CountResumed]. It is a read, and a newer answer to
///   "is a count already open" makes an older one worthless.
final class CountBloc extends Bloc<CountEvent, CountState> {
  /// Creates the bloc for one courier.
  CountBloc({required this._inventory, required this._courier})
    : super(const CountIdle()) {
    on<CountResumed>(_onResumed, transformer: restartable());
    on<CountStarted>(_onStarted, transformer: droppable());
    on<ParcelScanned>(_onScanned, transformer: sequential());
    on<CountFinished>(_onFinished, transformer: droppable());
  }

  final VehicleInventoryFacade _inventory;
  final ActorId _courier;

  /// Picks up a count that was already open, or leaves the screen idle.
  ///
  /// A phone that was killed mid-count leaves one behind, and a courier who
  /// had to start again would rescan a van they had already half counted —
  /// which is how a count ends up disagreeing with itself.
  Future<void> _onResumed(CountResumed event, Emitter<CountState> emit) async {
    emit(const CountPreparing());

    final open = await _inventory.openCountFor(_courier);
    emit(
      switch (open) {
        Success(value: final count?) => CountInProgress(count),
        Success() => const CountIdle(),
        Failed(:final failure) => CountFailed(failure),
      },
    );
  }

  Future<void> _onStarted(CountStarted event, Emitter<CountState> emit) async {
    emit(const CountPreparing());
    emit(
      _settled(
        await _inventory.startCount(
          courier: _courier,
          direction: event.direction,
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
  Future<void> _onScanned(ParcelScanned event, Emitter<CountState> emit) async {
    if (state case CountInProgress(:final count)) {
      emit(
        _settled(
          await _inventory.scan(count: count.id, shipment: event.shipment),
        ),
      );
    }
  }

  Future<void> _onFinished(
    CountFinished event,
    Emitter<CountState> emit,
  ) async {
    if (state case CountInProgress(:final count)) {
      final closed = await _inventory.close(count.id);
      emit(
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
}
