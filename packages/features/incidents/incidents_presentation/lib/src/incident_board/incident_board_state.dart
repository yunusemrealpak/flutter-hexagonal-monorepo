import 'package:incidents_api/incidents_api.dart';

/// What the incident board can be showing.
sealed class IncidentBoardState {
  const IncidentBoardState();
}

/// Nothing has been asked for yet.
final class BoardIdle extends IncidentBoardState {
  /// Creates the state.
  const BoardIdle();
}

/// The board is being read.
final class BoardLoading extends IncidentBoardState {
  /// Creates the state.
  const BoardLoading();
}

/// The board arrived.
///
/// [incidents] may be empty, and that is a different thing from [BoardFailed]:
/// a day with nothing open is a good day, and showing an error for it would
/// send a dispatcher looking for a problem that does not exist.
final class BoardReady extends IncidentBoardState {
  /// Creates the state.
  const BoardReady(this.incidents);

  /// What is still open, worst and oldest first.
  final List<Incident> incidents;
}

/// The board could not be read, or something asked of it was refused.
final class BoardFailed extends IncidentBoardState {
  /// Creates the state.
  const BoardFailed(this.failure);

  /// What went wrong, in incidents' own words.
  final IncidentsFailure failure;
}
