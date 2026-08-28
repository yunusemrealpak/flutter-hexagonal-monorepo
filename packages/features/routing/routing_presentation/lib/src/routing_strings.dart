/// Every string key this package asks an app to answer.
abstract final class RoutingStrings {
  /// The route screen's title.
  static const String title = 'routing.title';

  /// Shown before a route has been planned.
  ///
  /// Not an error — this is where every day starts — which is why it is its
  /// own key rather than the `NoPlan` failure's.
  static const String unplanned = 'routing.unplanned';

  /// Shown when a route was planned and has no stops in it.
  static const String nothingToDrive = 'routing.nothingToDrive';

  /// The summary line. Takes `stops` and `finishesAt` arguments.
  ///
  /// `finishesAt` crosses as a UTC `DateTime`, not as text. Turning an instant
  /// into a courier's wall clock needs a timezone and a locale, and the app is
  /// the only thing that has both.
  static const String summary = 'routing.summary';

  /// A stop's arrival time. Takes an `arrivesAt` argument, a UTC `DateTime`.
  static const String arrivesAt = 'routing.stop.arrivesAt';

  /// The stop being driven to now.
  static const String next = 'routing.stop.next';

  /// The stop is forecast to be reached after its window.
  static const String late = 'routing.stop.late';

  /// The stop has been visited.
  static const String done = 'routing.stop.done';

  /// The action that records arriving at a stop.
  static const String arrived = 'routing.stop.arrived';

  /// The action that moves a stop earlier in the order.
  static const String moveUp = 'routing.stop.moveUp';

  /// No route has been planned.
  static const String failureNoPlan = 'routing.failure.noPlan';

  /// The order sent does not describe this route.
  static const String failureSequenceMismatch =
      'routing.failure.sequenceMismatch';

  /// The stops cannot all be fitted in.
  static const String failureUnsatisfiable = 'routing.failure.unsatisfiable';

  /// One stop has no location. Takes an `address` argument.
  static const String failureNotGeocoded = 'routing.failure.notGeocoded';

  /// There is no position fix, so this is the route as planned.
  static const String failurePositionUnavailable =
      'routing.failure.positionUnavailable';

  /// The planner could not be reached, so this route came off the device.
  static const String failurePlannerUnavailable =
      'routing.failure.plannerUnavailable';

  /// A stored route value could not be read. Takes a `field` argument.
  static const String failureMalformed = 'routing.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    title,
    unplanned,
    nothingToDrive,
    summary,
    arrivesAt,
    next,
    late,
    done,
    arrived,
    moveUp,
    failureNoPlan,
    failureSequenceMismatch,
    failureUnsatisfiable,
    failureNotGeocoded,
    failurePositionUnavailable,
    failurePlannerUnavailable,
    failureMalformed,
  ];
}
