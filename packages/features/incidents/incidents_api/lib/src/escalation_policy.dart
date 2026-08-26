import 'incident_category.dart';
import 'incident_severity.dart';

/// How long an incident may sit before it is raised a step.
///
/// **In the contract rather than in `incidents_core`**, and this is the
/// opposite call from `ResolveLanguage` in settings — worth reading the two
/// together. A language bundle exists or does not exist in a *build*; how
/// long a damaged parcel may sit before somebody is told is a rule of the
/// *operation*, and a dispatcher's screen has to be able to say "escalates in
/// four hours" without asking an implementation.
///
/// It is data with a lookup, not a switch: the table below is one an operation
/// changes, and a `switch` in a use case would make every change a code review
/// about severity levels rather than about the operation.
final class EscalationPolicy {
  /// Creates a policy from a table of waits.
  ///
  /// The table is keyed by the severity an incident currently holds, because
  /// that is what governs how long it may stay there. A table keyed by
  /// category would have to be re-read after every escalation and would say
  /// nothing about an incident that had already moved.
  const EscalationPolicy({required this._waits});

  /// The waits the product ships with.
  ///
  /// Short at the top on purpose: a critical incident that nobody has picked
  /// up in fifteen minutes is the one worth interrupting somebody over, and a
  /// routine one can wait for the end of the round.
  const EscalationPolicy.standard()
    : _waits = const {
        IncidentSeverity.routine: Duration(hours: 4),
        IncidentSeverity.urgent: Duration(hours: 1),
        IncidentSeverity.critical: Duration(minutes: 15),
      };

  final Map<IncidentSeverity, Duration> _waits;

  /// How long an incident at [severity] may sit before it is raised.
  Duration waitFor(IncidentSeverity severity) =>
      _waits[severity] ?? const Duration(hours: 4);

  /// Whether an incident of [category] at [severity] that has been waiting
  /// [age] should be raised a step.
  ///
  /// [category] is taken and deliberately unused by the standard table. It is
  /// on the signature because the first operation-specific policy anybody
  /// writes is "damage escalates faster than everything else", and adding a
  /// parameter to this method later would be a breaking change to a contract
  /// three packages read.
  bool shouldEscalate({
    required IncidentCategory category,
    required IncidentSeverity severity,
    required Duration age,
  }) => severity != severity.escalated && age >= waitFor(severity);
}
