/// What has to be true of the device before scheduled work is allowed to run.
///
/// Technology words rather than product ones, like everything else in this
/// package: a caller says *this needs a connection*, not *this is a sync*.
///
/// Nothing is required by default. A constraint is a promise the operating
/// system makes about when it will wake the app, and every one of them is also
/// a reason it never does — an app that asked for charging and an unmetered
/// network on a courier's handset would schedule work that runs overnight in a
/// depot and never on a round.
final class TaskConstraints {
  /// Creates a set of constraints.
  const TaskConstraints({
    this.networkRequired = false,
    this.chargingRequired = false,
    this.batteryNotLow = false,
  });

  /// Whether the device must believe it has a connection.
  ///
  /// "Believe" is exact: both platforms answer from their own connectivity
  /// state, which is the same thing `connectivity_monitor` warns about. Work
  /// that requires a network still has to cope with not having one.
  final bool networkRequired;

  /// Whether the device must be on a charger.
  final bool chargingRequired;

  /// Whether the battery must be above the system's low threshold.
  final bool batteryNotLow;

  /// Whether nothing at all is required.
  bool get isEmpty => !networkRequired && !chargingRequired && !batteryNotLow;

  @override
  String toString() =>
      'TaskConstraints(network: $networkRequired, charging: '
      '$chargingRequired, batteryNotLow: $batteryNotLow)';
}
