import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'incident.dart';
import 'incident_category.dart';
import 'incident_id.dart';
import 'incidents_failure.dart';

/// What the rest of the product may ask incidents to do.
///
/// A driving port, speaking in `ActorId` and `ShipmentId` because every caller
/// already holds them. `IncidentLog` beside it speaks in whole incidents and
/// nothing else — an adapter has no business knowing who is signed in.
abstract interface class IncidentsFacade {
  /// Records an exception.
  ///
  /// [shipmentId] is optional: a vehicle breakdown concerns no parcel.
  Future<Result<Incident, IncidentsFailure>> report({
    required ActorId reportedBy,
    required IncidentCategory category,
    ShipmentId? shipmentId,
    String? note,
  });

  /// Everything still waiting for somebody, worst and oldest first.
  Future<Result<List<Incident>, IncidentsFailure>> open();

  /// Raises every incident that has been waiting too long, and answers with
  /// the ones it raised.
  ///
  /// Idempotent by design: running it twice in a minute raises nothing the
  /// second time, because escalation resets the clock it measures against.
  /// That is what lets an app call it on a timer without coordinating.
  Future<Result<List<Incident>, IncidentsFailure>> escalateOverdue();

  /// Closes one incident, recording what was done about it.
  Future<Result<Incident, IncidentsFailure>> resolve({
    required IncidentId id,
    required String outcome,
  });
}
