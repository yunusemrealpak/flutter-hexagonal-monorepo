import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'escalate_overdue.dart';
import 'list_open_incidents.dart';
import 'report_incident.dart';
import 'resolve_incident.dart';

/// The one implementation of `IncidentsFacade`.
///
/// It composes use cases and holds no rule of its own. Every method is one
/// line, and that is the shape to keep: the day one of them grows a branch,
/// the branch belongs in a use case where a test can reach it without a
/// facade.
///
/// `report` requires an `ActorId` while `ReportIncidentCommand` does not. The
/// difference is deliberate — this is the surface a *person* reports through,
/// and an anonymous report from a screen would be a record nobody can be asked
/// about. The watcher, which has no person behind it, uses the use case
/// directly.
final class IncidentsCoordinator implements IncidentsFacade {
  /// Creates the coordinator over its use cases.
  const IncidentsCoordinator({
    required this._report,
    required this._list,
    required this._escalate,
    required this._resolve,
  });

  final ReportIncident _report;
  final ListOpenIncidents _list;
  final EscalateOverdue _escalate;
  final ResolveIncident _resolve;

  @override
  Future<Result<Incident, IncidentsFailure>> report({
    required ActorId reportedBy,
    required IncidentCategory category,
    ShipmentId? shipmentId,
    String? note,
  }) => _report(
    ReportIncidentCommand(
      category: category,
      reportedBy: reportedBy,
      shipmentId: shipmentId,
      note: note,
    ),
  );

  @override
  Future<Result<List<Incident>, IncidentsFailure>> open() => _list(());

  @override
  Future<Result<List<Incident>, IncidentsFailure>> escalateOverdue() =>
      _escalate(());

  @override
  Future<Result<Incident, IncidentsFailure>> resolve({
    required IncidentId id,
    required String outcome,
  }) => _resolve(ResolveIncidentCommand(id: id, outcome: outcome));
}
