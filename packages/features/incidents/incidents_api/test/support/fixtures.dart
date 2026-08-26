import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// A fixed instant, so that no test in this package needs a clock.
final DateTime opened = DateTime.utc(2026, 3, 4, 9);

/// The courier every fixture is reported by.
final ActorId courier =
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// The parcel most fixtures concern.
final ShipmentId parcel =
    (ShipmentId.parse('SHP-42') as Success<ShipmentId, ShipmentFailure>).value;

/// Reads an incident identifier, throwing on an invalid fixture.
IncidentId id(String raw) =>
    (IncidentId.parse(raw) as Success<IncidentId, IncidentsFailure>).value;

/// An open incident of [category].
Incident open({
  IncidentCategory category = IncidentCategory.recipientUnavailable,
  String? note,
  ShipmentId? shipment,
}) =>
    (Incident.opened(
              id: id('INC-1'),
              category: category,
              openedAt: opened,
              reportedBy: courier,
              shipmentId: shipment ?? parcel,
              note: note,
            )
            as Success<Incident, IncidentsFailure>)
        .value;

/// The incident behind a successful result.
Incident valueOf(Result<Incident, IncidentsFailure> result) =>
    (result as Success<Incident, IncidentsFailure>).value;

/// The failure behind an unsuccessful one.
IncidentsFailure failureOf(Result<Incident, IncidentsFailure> result) =>
    (result as Failed<Incident, IncidentsFailure>).failure;
