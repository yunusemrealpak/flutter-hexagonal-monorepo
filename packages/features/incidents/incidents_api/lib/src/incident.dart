import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'incident_category.dart';
import 'incident_id.dart';
import 'incident_severity.dart';
import 'incidents_failure.dart';

/// One exception on a round, from the moment it is recorded to the moment
/// somebody closes it.
///
/// An `Entity`: an incident that has been escalated is still the same
/// incident. Behaviour lives here rather than in a use case, so that no
/// adapter and no screen can produce a state the product does not have —
/// there is no way to build a resolved incident that was never opened, and no
/// way to escalate one that is already closed.
///
/// **It names two foreign identifiers and no foreign model.** [shipmentId] and
/// [reportedBy] cross from `shipments_api` and `identity_api`; nothing about
/// what is in the parcel or who the courier is crosses with them. That is
/// `docs/DEPENDENCY_RULES.md` §2.1, and it is why this feature can be read
/// without either of the other two open.
///
/// **Both of them are nullable, and each for its own reason.** A vehicle
/// breakdown is an incident with no parcel attached, so requiring a
/// [shipmentId] would force a caller to invent one and every report of
/// "incidents by shipment" would quietly include it. A [reportedBy] of `null`
/// means the product opened the incident itself, from a domain event, with no
/// human at the other end — attributing that to whoever happened to be signed
/// in would put a courier's name on a record they never made.
final class Incident extends Entity<IncidentId> {
  const Incident._({
    required super.id,
    required this.category,
    required this.severity,
    required this.note,
    required this.shipmentId,
    required this.reportedBy,
    required this.openedAt,
    required this.escalatedAt,
    required this.resolvedAt,
    required this.resolution,
  });

  /// Records an exception that has just happened.
  ///
  /// [openedAt] comes from a `Clock` — rule A1, and the reason this factory
  /// takes it rather than reading it.
  ///
  /// A note is required for [IncidentCategory.damage] and optional otherwise,
  /// for the reason `NonDeliveryReason.damagedInTransit` gives in delivery:
  /// this is the case that becomes a claim against a carrier months later, and
  /// "damaged" with nothing after it is not something anybody can act on.
  static Result<Incident, IncidentsFailure> opened({
    required IncidentId id,
    required IncidentCategory category,
    required DateTime openedAt,
    ActorId? reportedBy,
    ShipmentId? shipmentId,
    String? note,
  }) {
    final trimmed = note?.trim();
    if (category == IncidentCategory.damage &&
        (trimmed == null || trimmed.isEmpty)) {
      return const Failed(
        MalformedIncident(
          field: 'note',
          reason: 'damage is a claim, and a claim needs describing',
        ),
      );
    }

    return Success(
      Incident._(
        id: id,
        category: category,
        severity: IncidentSeverity.initialFor(category),
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
        shipmentId: shipmentId,
        reportedBy: reportedBy,
        openedAt: openedAt.toUtc(),
        escalatedAt: null,
        resolvedAt: null,
        resolution: null,
      ),
    );
  }

  /// Rebuilds an incident that was already recorded.
  ///
  /// Separate from [opened] because a freshly opened incident is unescalated
  /// and unresolved by definition, and one factory taking every field
  /// nullable would let a caller construct an incident that was resolved
  /// before it was opened.
  static Result<Incident, IncidentsFailure> stored({
    required IncidentId id,
    required IncidentCategory category,
    required IncidentSeverity severity,
    required DateTime openedAt,
    required ActorId? reportedBy,
    required DateTime? escalatedAt,
    required DateTime? resolvedAt,
    ShipmentId? shipmentId,
    String? note,
    String? resolution,
  }) {
    final opening = openedAt.toUtc();
    for (final later in {
      'escalatedAt': escalatedAt,
      'resolvedAt': resolvedAt,
    }.entries) {
      final instant = later.value;
      if (instant != null && instant.toUtc().isBefore(opening)) {
        return Failed(
          MalformedIncident(
            field: later.key,
            reason: 'it is before the incident was opened',
          ),
        );
      }
    }

    return Success(
      Incident._(
        id: id,
        category: category,
        severity: severity,
        note: note,
        shipmentId: shipmentId,
        reportedBy: reportedBy,
        openedAt: opening,
        escalatedAt: escalatedAt?.toUtc(),
        resolvedAt: resolvedAt?.toUtc(),
        resolution: resolution,
      ),
    );
  }

  /// What kind of exception it is.
  final IncidentCategory category;

  /// How quickly somebody has to act.
  final IncidentSeverity severity;

  /// What the person who reported it wrote, when they wrote anything.
  final String? note;

  /// Which parcel it concerns, or `null` when it concerns none.
  final ShipmentId? shipmentId;

  /// Who reported it, or `null` when the product opened it itself.
  final ActorId? reportedBy;

  /// When it was recorded, in UTC.
  final DateTime openedAt;

  /// When it was last escalated, or `null` while it never has been.
  final DateTime? escalatedAt;

  /// When it was closed, or `null` while it is open.
  final DateTime? resolvedAt;

  /// What was done about it, recorded when it was closed.
  final String? resolution;

  /// Whether somebody still has to do something about it.
  bool get isOpen => resolvedAt == null;

  /// How long it has been open at [instant].
  ///
  /// Measured from the last escalation when there has been one, and from the
  /// opening otherwise. Measuring from the opening throughout would escalate a
  /// critical incident to critical again on every sweep, and the board would
  /// fill with movement nobody caused.
  Duration ageAt(DateTime instant) =>
      instant.toUtc().difference(escalatedAt ?? openedAt);

  /// Raises the severity one step.
  ///
  /// Refuses a closed incident: escalating something somebody has already
  /// dealt with is not a race, it is a bug in the caller. Succeeds and changes
  /// nothing when the severity is already the highest there is — the sweep
  /// that calls this runs repeatedly, and a failure for "already critical"
  /// would make every sweep report errors for the incidents that need it most.
  Result<Incident, IncidentsFailure> escalatedAtInstant(DateTime instant) {
    if (!isOpen) {
      return const Failed(
        IncidentNotInState(attempted: 'escalate', state: 'resolved'),
      );
    }
    if (severity == severity.escalated) {
      return Success(this);
    }

    return Success(
      Incident._(
        id: id,
        category: category,
        severity: severity.escalated,
        note: note,
        shipmentId: shipmentId,
        reportedBy: reportedBy,
        openedAt: openedAt,
        escalatedAt: instant.toUtc(),
        resolvedAt: null,
        resolution: resolution,
      ),
    );
  }

  /// Closes the incident.
  ///
  /// Refuses a second closing, and refuses an empty account of what was done.
  /// An incident closed with nothing written against it is one nobody can
  /// learn from, and the whole reason this feature exists is that somebody
  /// reads these later.
  Result<Incident, IncidentsFailure> resolvedAtInstant(
    DateTime instant,
    String outcome,
  ) {
    if (!isOpen) {
      return const Failed(
        IncidentNotInState(attempted: 'resolve', state: 'resolved'),
      );
    }
    final trimmed = outcome.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedIncident(field: 'resolution', reason: 'it is empty'),
      );
    }

    return Success(
      Incident._(
        id: id,
        category: category,
        severity: severity,
        note: note,
        shipmentId: shipmentId,
        reportedBy: reportedBy,
        openedAt: openedAt,
        escalatedAt: escalatedAt,
        resolvedAt: instant.toUtc(),
        resolution: trimmed,
      ),
    );
  }
}
