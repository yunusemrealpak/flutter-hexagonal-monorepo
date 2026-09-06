import 'package:identity_api/identity_api.dart';

/// What can happen to the dispatcher's board.
sealed class DispatcherBoardEvent {
  const DispatcherBoardEvent();
}

/// Fetch the board from the beginning.
final class BoardRequested extends DispatcherBoardEvent {
  /// Creates the event.
  const BoardRequested();
}

/// Fetch the page after the one on screen, keeping the ticks.
final class MoreRequested extends DispatcherBoardEvent {
  /// Creates the event.
  const MoreRequested();
}

/// Tick or untick one row.
final class RowToggled extends DispatcherBoardEvent {
  /// Creates the event.
  const RowToggled(this.shipmentId);

  /// Which row.
  final String shipmentId;
}

/// Assign every ticked shipment to one courier.
///
/// An event rather than a method that answers its caller, and the change is
/// what makes the operation reachable at all: a bloc is in the tree, so an app
/// that has a courier to name can drive this from wherever its picker lives.
/// The outcome goes where every other outcome on this screen goes — into the
/// state.
final class SelectionAssigned extends DispatcherBoardEvent {
  /// Creates the event.
  const SelectionAssigned(this.courier);

  /// Who the ticked shipments go to.
  final ActorId courier;
}
