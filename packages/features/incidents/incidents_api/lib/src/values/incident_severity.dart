import 'incident_category.dart';

/// How quickly somebody has to do something about an incident.
///
/// Ordered, and the order is used: escalation compares severities, and a
/// dispatcher's board sorts by them. `index` is the comparison, which is why
/// the members are declared worst-last rather than in the order they were
/// thought of.
enum IncidentSeverity {
  /// Somebody will deal with it in the ordinary course of the day.
  routine,

  /// It needs attention before the round ends.
  urgent,

  /// Somebody has to be told now.
  critical;

  /// Where an incident of [category] starts.
  ///
  /// A starting point, not a fixed property: an incident can be escalated
  /// above it, and `EscalationPolicy` decides when. Keeping the initial
  /// severity on the severity type rather than on the category is what lets an
  /// operation change the table without touching the taxonomy — the two change
  /// for different reasons and at different speeds.
  static IncidentSeverity initialFor(IncidentCategory category) =>
      switch (category) {
        IncidentCategory.fieldEmergency => IncidentSeverity.critical,
        IncidentCategory.damage => IncidentSeverity.urgent,
        IncidentCategory.addressNotFound ||
        IncidentCategory.recipientUnavailable ||
        IncidentCategory.accessDenied ||
        IncidentCategory.unclassified => IncidentSeverity.routine,
      };

  /// The next severity up, or this one when there is nowhere higher to go.
  IncidentSeverity get escalated =>
      index + 1 < values.length ? values[index + 1] : this;
}
