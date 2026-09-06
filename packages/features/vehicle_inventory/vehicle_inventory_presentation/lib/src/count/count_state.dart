import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// What the counting screen can be showing.
///
/// [CountInProgress] is the state the screen is in almost the whole time it is
/// open, and it carries the count itself — so the missing and unexpected lists
/// the courier reads are derived by `LoadCount` rather than assembled here. A
/// screen that computed them would be a second implementation of the only
/// arithmetic this feature has.
sealed class CountState {
  const CountState();
}

/// Nothing has been asked for yet.
final class CountIdle extends CountState {
  /// Creates the state.
  const CountIdle();
}

/// The manifest is being fetched, or the count read back.
final class CountPreparing extends CountState {
  /// Creates the state.
  const CountPreparing();
}

/// Somebody is scanning.
final class CountInProgress extends CountState {
  /// Creates the state.
  const CountInProgress(this.count);

  /// The count as it stands.
  final LoadCount count;
}

/// The count is closed and the result is on screen.
final class CountClosedState extends CountState {
  /// Creates the state.
  const CountClosedState(this.count);

  /// The count as it was closed.
  final LoadCount count;
}

/// Something went wrong.
final class CountFailed extends CountState {
  /// Creates the state.
  const CountFailed(this.failure);

  /// What went wrong, in this feature's own words.
  final VehicleInventoryFailure failure;
}
