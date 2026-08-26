import 'package:core_kernel/core_kernel.dart';
import 'package:incidents_api/incidents_api.dart';

/// Reads everything still waiting for somebody, worst and oldest first.
///
/// The ordering is applied here rather than trusted from the log, for the
/// reason `ReadInbox` gives in notifications: a store that returns rows in
/// insertion order and one that returns them in whatever order a database
/// chose are both legal `IncidentLog`s.
///
/// Worst first, then oldest. A dispatcher works down the board, and a critical
/// incident from ten minutes ago outranks a routine one from this morning —
/// while two of the same severity are a queue, and the one that has waited
/// longest is the one somebody has been waiting on.
final class ListOpenIncidents
    implements UseCase<(), Result<List<Incident>, IncidentsFailure>> {
  /// Creates the use case.
  const ListOpenIncidents({required this._log});

  final IncidentLog _log;

  @override
  Future<Result<List<Incident>, IncidentsFailure>> call(() input) async {
    final read = await _log.all();

    return read.map(
      (incidents) =>
          incidents.where((incident) => incident.isOpen).toList()..sort(
            (a, b) => a.severity == b.severity
                ? a.openedAt.compareTo(b.openedAt)
                : b.severity.index.compareTo(a.severity.index),
          ),
    );
  }
}
