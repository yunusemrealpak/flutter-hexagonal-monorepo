import 'package:shipments_api/shipments_api.dart';

/// What the dispatcher's board can be showing.
///
/// The same four shapes as the courier's stop list, and deliberately not
/// shared with it. They look alike today and diverge the moment the board
/// grows a selection, a filter or a sort — and the shared type would then have
/// three fields the courier's screen never sets. Two features that happen to
/// have the same state shape are not the same feature, and a `shared` package
/// for it is exactly the mistake the constitution forbids.
sealed class DispatcherBoardState {
  const DispatcherBoardState();
}

/// Nothing has been asked for yet.
final class BoardIdle extends DispatcherBoardState {
  /// Creates the state.
  const BoardIdle();
}

/// The board is being fetched.
final class BoardLoading extends DispatcherBoardState {
  /// Creates the state.
  const BoardLoading();
}

/// The board arrived.
final class BoardReady extends DispatcherBoardState {
  /// Creates the state.
  const BoardReady({required this.rows, this.selected = const {}});

  /// Every shipment on the board.
  final List<ShipmentSummary> rows;

  /// The identifiers the dispatcher has ticked, for a bulk action.
  final Set<String> selected;

  /// Returns a copy with [selected] replaced.
  BoardReady withSelection(Set<String> selection) =>
      BoardReady(rows: rows, selected: selection);
}

/// The board could not be fetched.
final class BoardFailed extends DispatcherBoardState {
  /// Creates the state.
  const BoardFailed(this.failure);

  /// What went wrong, in shipments' own words.
  final ShipmentFailure failure;
}
