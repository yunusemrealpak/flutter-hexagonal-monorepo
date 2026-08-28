import 'package:incidents_api/incidents_api.dart';

/// Every string key this package asks an app to answer.
///
/// The category and severity keys are derived from the enums they label rather
/// than written out, so adding an `IncidentCategory` adds a key to [all] and
/// an app's coverage test fails until somebody writes the sentence. A
/// hand-written list would have let a new category ship showing its own key on
/// a dispatcher's board.
abstract final class IncidentsStrings {
  /// The board's title.
  static const String boardTitle = 'incidents.board.title';

  /// Shown when nothing is open.
  static const String boardClear = 'incidents.board.clear';

  /// The incident log could not be read.
  static const String failureLogUnavailable =
      'incidents.failure.logUnavailable';

  /// The incident is no longer open.
  static const String failureMissing = 'incidents.failure.missing';

  /// The transition asked for is not possible from where the incident is.
  ///
  /// Takes an `attempted` argument.
  static const String failureNotInState = 'incidents.failure.notInState';

  /// A stored incident could not be read. Takes a `field` argument.
  static const String failureMalformed = 'incidents.failure.malformed';

  /// The key for one category.
  static String category(IncidentCategory category) =>
      'incidents.category.${category.name}';

  /// The key for one severity.
  static String severity(IncidentSeverity severity) =>
      'incidents.severity.${severity.name}';

  /// Every key above, for an app's coverage test.
  static final List<String> all = [
    boardTitle,
    boardClear,
    failureLogUnavailable,
    failureMissing,
    failureNotInState,
    failureMalformed,
    for (final value in IncidentCategory.values) category(value),
    for (final value in IncidentSeverity.values) severity(value),
  ];
}
