import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:incidents_api/incidents_api.dart';

/// Which incident, and what was done about it.
final class ResolveIncidentCommand {
  /// Creates the command.
  const ResolveIncidentCommand({required this.id, required this.outcome});

  /// Which incident.
  final IncidentId id;

  /// What was done. Refused when empty — see `Incident.resolvedAtInstant`.
  final String outcome;
}

/// Closes one incident.
///
/// Reads, asks the entity, writes. The entity is what refuses a second closing
/// and an empty account of what was done; this use case only decides *when*,
/// which is what the `Clock` is for.
final class ResolveIncident
    implements
        UseCase<ResolveIncidentCommand, Result<Incident, IncidentsFailure>> {
  /// Creates the use case.
  const ResolveIncident({required this._log, required this._clock});

  final IncidentLog _log;
  final Clock _clock;

  @override
  Future<Result<Incident, IncidentsFailure>> call(
    ResolveIncidentCommand command,
  ) async {
    final read = await _log.all();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final log = (read as Success<List<Incident>, IncidentsFailure>).value;
    final index = log.indexWhere((incident) => incident.id == command.id);
    if (index < 0) {
      return Failed(IncidentMissing(command.id.value));
    }

    final resolved = log[index].resolvedAtInstant(
      _clock.now(),
      command.outcome,
    );
    if (resolved case Failed(:final failure)) {
      return Failed(failure);
    }

    final next = (resolved as Success<Incident, IncidentsFailure>).value;
    final written = await _log.update(next);

    return switch (written) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(next),
    };
  }
}
