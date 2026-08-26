import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// What is being reported, and by whom.
///
/// [reportedBy] is nullable because this same use case serves both ways an
/// incident is opened: a person filling in a form, and the watcher reacting to
/// a `ShipmentFailed` event with nobody at the other end.
final class ReportIncidentCommand {
  /// Creates the command.
  const ReportIncidentCommand({
    required this.category,
    this.reportedBy,
    this.shipmentId,
    this.note,
  });

  /// What kind of exception it is.
  final IncidentCategory category;

  /// Who reported it, or `null` when the product did.
  final ActorId? reportedBy;

  /// Which parcel it concerns, when it concerns one.
  final ShipmentId? shipmentId;

  /// What the reporter wrote.
  final String? note;
}

/// Records an exception.
///
/// The identifier comes from `IdGenerator` and the instant from `Clock` —
/// rules A1 and A3 — which is what lets the tests assert on both instead of
/// matching them with a wildcard.
///
/// The entity's own guards do the refusing: `Incident.opened` is what insists
/// on a note for damage. This use case does not repeat that check, and the
/// reason is worth stating — a rule enforced in two places is a rule that will
/// disagree with itself, and the copy in the use case is the one an adapter
/// can bypass.
final class ReportIncident
    implements
        UseCase<ReportIncidentCommand, Result<Incident, IncidentsFailure>> {
  /// Creates the use case.
  const ReportIncident({
    required this._log,
    required this._clock,
    required this._ids,
  });

  final IncidentLog _log;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<Incident, IncidentsFailure>> call(
    ReportIncidentCommand command,
  ) async {
    final built = IncidentId.parse(_ids.newId()).flatMap(
      (id) => Incident.opened(
        id: id,
        category: command.category,
        openedAt: _clock.now(),
        reportedBy: command.reportedBy,
        shipmentId: command.shipmentId,
        note: command.note,
      ),
    );
    if (built case Failed(:final failure)) {
      return Failed(failure);
    }

    final incident = (built as Success<Incident, IncidentsFailure>).value;
    final opened = await _log.open(incident);

    return switch (opened) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(incident),
    };
  }
}
