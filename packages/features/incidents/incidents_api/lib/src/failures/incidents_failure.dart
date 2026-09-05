import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the incidents ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
sealed class IncidentsFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const IncidentsFailure();
}

/// The record could not be read or written.
final class IncidentLogUnavailable extends IncidentsFailure {
  /// Records that the log did not answer, with an optional [detail] for the
  /// log.
  const IncidentLogUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'IncidentLogUnavailable(${detail ?? 'no detail'})';
}

/// There is no incident under the identifier that was asked for.
final class IncidentMissing extends IncidentsFailure {
  /// Records that [id] is not in the log.
  const IncidentMissing(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'IncidentMissing($id)';
}

/// The incident is in a state where what was asked for makes no sense.
///
/// Resolving an incident twice, or escalating one that is already closed.
/// [attempted] says what was asked for and [state] what the incident was in,
/// because a message that only said "invalid" would send somebody to the log
/// to find out which.
final class IncidentNotInState extends IncidentsFailure {
  /// Records that [attempted] was asked of an incident that is [state].
  const IncidentNotInState({required this.attempted, required this.state});

  /// What was asked for.
  final String attempted;

  /// What the incident actually is.
  final String state;

  @override
  String toString() => 'IncidentNotInState($attempted on $state)';
}

/// A value an incident carries was refused at construction.
final class MalformedIncident extends IncidentsFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedIncident({required this.field, required this.reason});

  /// Which part refused its value.
  final String field;

  /// Why it was refused.
  final String reason;

  @override
  String toString() => 'MalformedIncident($field: $reason)';
}
