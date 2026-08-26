/// The incidents contract: what an exception on a round is recorded as, when
/// it escalates, and the port that keeps the record.
///
/// **`IncidentCategory` is not `NonDeliveryReason`.** Delivery's union answers
/// "why did this visit end without a hand-over"; this enum answers "how fast
/// does somebody have to do something". They overlap and are not the same
/// question — `rescheduled` is a delivery outcome and never an incident,
/// `fieldEmergency` is an incident and never a delivery outcome — and
/// borrowing delivery's model would have made this feature unable to record an
/// exception that had no delivery attempt behind it. Section 2.1 of
/// `docs/DEPENDENCY_RULES.md` is the rule; this is what it looks like when it
/// is followed on the first commit rather than after a rewrite.
///
/// **`EscalationPolicy` is in the contract**, unlike settings'
/// `ResolveLanguage`, which is not. The difference is what the rule belongs
/// to: a language bundle exists or does not exist in a build, while how long a
/// damaged parcel may sit is a rule of the operation, and a dispatcher's
/// screen has to be able to state it.
library;

export 'src/escalation_policy.dart';
export 'src/incident.dart';
export 'src/incident_category.dart';
export 'src/incident_id.dart';
export 'src/incident_log.dart';
export 'src/incident_severity.dart';
export 'src/incidents_facade.dart';
export 'src/incidents_failure.dart';
