/// Every string key this package asks an app to answer.
abstract final class ReportingStrings {
  /// The report screen's title.
  static const String title = 'reports.title';

  /// Shown to somebody whose permissions do not include this screen.
  static const String forbidden = 'reports.forbidden';

  /// The heading over the day's totals.
  static const String totalsSection = 'reports.totals.section';

  /// How many shipments the range covers. Takes a `count` argument.
  static const String total = 'reports.total';

  /// How many of them were delivered. Takes a `count` argument.
  static const String delivered = 'reports.delivered';

  /// The heading over the per-day rows.
  static const String daysSection = 'reports.days.section';

  /// One day's success rate. Takes `day` and `rate` arguments.
  ///
  /// `rate` is a whole number of percentage points, not a formatted string:
  /// where the sign goes and whether there is a space before it are the app's
  /// questions, and a screen that answered them would answer them once for
  /// every locale.
  static const String dayRate = 'reports.day.rate';

  /// The figures could not be read.
  static const String failureTallyUnavailable =
      'reports.failure.tallyUnavailable';

  /// The range asked for starts after it ends.
  static const String failureRangeInverted = 'reports.failure.rangeInverted';

  /// Some of the stored figures could not be read.
  static const String failureMalformed = 'reports.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    title,
    forbidden,
    totalsSection,
    total,
    delivered,
    daysSection,
    dayRate,
    failureTallyUnavailable,
    failureRangeInverted,
    failureMalformed,
  ];
}
