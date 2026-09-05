import 'package:core_kernel/core_kernel.dart';

import '../failures/reporting_failure.dart';

/// One operating day, as the operation counts them.
///
/// **Derived from an instant, in UTC, and that is a decision with a cost.** A
/// round that runs past midnight local time is split across two days in the
/// totals, and a fleet spread across time zones is counted on one clock rather
/// than on each courier's.
///
/// The alternative — attributing a day by the courier's local time — makes a
/// tally that cannot be summed across a fleet without knowing where every
/// courier was standing, and makes yesterday's total change when somebody
/// travels. This is the boring choice on purpose; an operation that needs
/// local days can render them from the same events later.
final class ReportingDay extends ValueObject<String> {
  const ReportingDay._(super.value);

  /// The day [instant] falls in.
  factory ReportingDay.of(DateTime instant) {
    final utc = instant.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return ReportingDay._('${utc.year}-$month-$day');
  }

  /// Reads a day from its stored spelling.
  ///
  /// The check is a round trip rather than a parse, and it needs two guards
  /// that a naive one misses. `DateTime.tryParse` is **lenient**: it reads
  /// `2026-13-01` as the first of January 2027 and reports no error. It is
  /// also **local**: a bare date is parsed in the device's zone, so east of
  /// Greenwich `2026-03-04` becomes an instant whose UTC day is the third.
  /// Parsing at midnight UTC explicitly and comparing the spelling that comes
  /// back out is what turns both of those into a refusal instead of a day
  /// silently off by one.
  static Result<ReportingDay, ReportingFailure> parse(String raw) {
    final trimmed = raw.trim();
    final parsed = DateTime.tryParse('${trimmed}T00:00:00Z');
    if (trimmed.length != 10 ||
        parsed == null ||
        ReportingDay.of(parsed).value != trimmed) {
      return Failed(
        MalformedTally(
          field: 'day',
          reason: '"$trimmed" is not a calendar day',
        ),
      );
    }
    return Success(ReportingDay._(trimmed));
  }

  /// Whether this day comes before [other].
  ///
  /// String comparison, and it is correct because the format is fixed-width
  /// and most-significant-first. Parsing to a `DateTime` to compare two days
  /// would be doing arithmetic to answer a question the spelling already
  /// answers.
  bool isBefore(ReportingDay other) => value.compareTo(other.value) < 0;
}
