import 'package:core_kernel/core_kernel.dart';

import '../failures/incidents_failure.dart';

/// What kind of exception was recorded, as far as escalation is concerned.
///
/// **Not `NonDeliveryReason`.** That union lives in `delivery_api`, carries a
/// note, a requested date and a retry rule, and belongs to the feature that
/// owns what happens at a door. Borrowing it would be borrowing a model, which
/// `docs/DEPENDENCY_RULES.md` §2.1 forbids for the reason phase 5 learned the
/// expensive way: this feature would then carry delivery's shape into every
/// signature it has, and could not record an incident that has nothing to do
/// with a delivery attempt.
///
/// The two taxonomies overlap and are not the same question. Delivery asks
/// *why the visit ended without a hand-over*; incidents asks *how fast
/// somebody has to do something about it*. `rescheduled` is a first-class
/// delivery outcome and not an incident at all; `vehicleBreakdown` is an
/// incident and never a delivery outcome.
enum IncidentCategory {
  /// The parcel arrived damaged.
  damage,

  /// The address could not be found, or does not exist.
  addressNotFound,

  /// Nobody was there to take it, repeatedly.
  recipientUnavailable,

  /// The courier could not get to the door.
  accessDenied,

  /// Something happened to the vehicle or the courier.
  fieldEmergency,

  /// Something the operation has not classified.
  ///
  /// Present so that an incident is never lost for want of a label. A round
  /// produces exceptions nobody anticipated, and a taxonomy that refused them
  /// would push couriers into picking the nearest wrong category — which is
  /// worse than an honest "other", because it is invisible in a report.
  unclassified;

  /// Reads a category from its stored spelling.
  static Result<IncidentCategory, IncidentsFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedIncident(
        field: 'category',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
