import 'package:core_kernel/core_kernel.dart';

import '../../entities/incident.dart';
import '../../failures/incidents_failure.dart';

/// Where recorded exceptions are kept.
///
/// A driven port: `incidents_core` answers it, and an app decides whether that
/// answer is device storage, an operations backend, or a map in a test.
///
/// Every method takes and returns incidents whole rather than fields. An
/// interface with `setSeverity` and `setResolution` on it would put the
/// state machine in the adapter, where `Incident`'s guards could not reach it.
abstract interface class IncidentLog {
  /// Every incident this device knows about, newest first.
  Future<Result<List<Incident>, IncidentsFailure>> all();

  /// Records a new incident.
  ///
  /// Recording one whose identifier is already present replaces nothing and
  /// fails nothing — the identifier is minted per incident, so a repeat is a
  /// retry of the same write.
  Future<Result<void, IncidentsFailure>> open(Incident incident);

  /// Replaces the incident with the same identifier.
  ///
  /// Fails with [IncidentMissing] when there is nothing to replace.
  Future<Result<void, IncidentsFailure>> update(Incident incident);
}
