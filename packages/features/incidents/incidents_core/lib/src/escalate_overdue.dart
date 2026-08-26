import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:incidents_api/incidents_api.dart';

/// Raises every incident that has been waiting too long.
///
/// **Idempotent, and that is a property of the entity rather than of a flag
/// here.** `Incident.ageAt` measures from the last escalation when there has
/// been one, so an incident this sweep raises is not overdue again until the
/// next wait has passed. A sweep that measured from the opening throughout
/// would raise the same incident on every run and fill a dispatcher's board
/// with movement nobody caused.
///
/// It answers with what it raised rather than with a count, because the caller
/// — a timer in an app, or a dispatcher's refresh — usually wants to say
/// *which* incidents moved.
///
/// A failure to write one incident does not stop the sweep. The rest are still
/// overdue, and a sweep that gave up on the first locked write would leave the
/// worst incident of the day unraised because an unrelated one could not be
/// stored.
final class EscalateOverdue
    implements UseCase<(), Result<List<Incident>, IncidentsFailure>> {
  /// Creates the use case.
  const EscalateOverdue({
    required this._log,
    required this._clock,
    required this._policy,
    required this._logger,
  });

  final IncidentLog _log;
  final Clock _clock;
  final EscalationPolicy _policy;
  final Logger _logger;

  @override
  Future<Result<List<Incident>, IncidentsFailure>> call(() input) async {
    final read = await _log.all();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final now = _clock.now();
    final raised = <Incident>[];

    for (final incident
        in (read as Success<List<Incident>, IncidentsFailure>).value) {
      if (!incident.isOpen) {
        continue;
      }
      if (!_policy.shouldEscalate(
        category: incident.category,
        severity: incident.severity,
        age: incident.ageAt(now),
      )) {
        continue;
      }

      final escalated = incident.escalatedAtInstant(now);
      if (escalated case Failed(:final failure)) {
        _logger.log(
          LogLevel.warning,
          'an incident could not be raised: $failure',
        );
        continue;
      }

      final next = (escalated as Success<Incident, IncidentsFailure>).value;
      final written = await _log.update(next);
      switch (written) {
        case Failed(:final failure):
          _logger.log(
            LogLevel.warning,
            'a raised incident could not be stored: $failure',
          );
        case Success():
          raised.add(next);
      }
    }

    return Success(raised);
  }
}
