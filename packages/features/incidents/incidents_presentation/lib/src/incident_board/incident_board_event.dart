import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// What can be asked of the incident board.
///
/// Three cases, and their three transformers are the argument for events over
/// methods in this feature: reading, recording and closing are all "one at a
/// time", and they mean three different things by it.
sealed class IncidentBoardEvent {
  const IncidentBoardEvent();
}

/// Read what is still open.
final class BoardRequested extends IncidentBoardEvent {
  /// Creates the event.
  const BoardRequested();
}

/// Record an exception.
final class IncidentReported extends IncidentBoardEvent {
  /// Creates the event.
  const IncidentReported({required this.category, this.shipmentId, this.note});

  /// What kind of exception it is.
  final IncidentCategory category;

  /// Which parcel it happened on, when it happened on one.
  final ShipmentId? shipmentId;

  /// What the person wrote, if anything.
  final String? note;
}

/// Close [id] with [outcome].
final class IncidentResolved extends IncidentBoardEvent {
  /// Creates the event.
  const IncidentResolved(this.id, this.outcome);

  /// Which incident is being closed.
  final IncidentId id;

  /// What was done about it.
  final String outcome;
}
