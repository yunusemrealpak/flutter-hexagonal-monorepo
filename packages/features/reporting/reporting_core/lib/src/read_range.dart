import 'package:core_kernel/core_kernel.dart';
import 'package:reporting_api/reporting_api.dart';

/// The two ends of a range, inclusive.
final class ReadRangeCommand {
  /// Creates the command.
  const ReadRangeCommand({required this.from, required this.to});

  /// The first day.
  final ReportingDay from;

  /// The last day.
  final ReportingDay to;
}

/// Reads every day between two dates, including the ones with nothing on them.
///
/// **A day with nothing on it is included as an empty tally.** A chart with a
/// gap where Sunday should be reads as missing data and sends somebody looking
/// for a synchronisation problem; a Sunday with zero on it reads as a Sunday.
///
/// An inverted range is refused rather than answered with nothing, because a
/// dispatcher can produce one from a date picker in a single tap and "from
/// Friday to Monday" deserves a sentence.
///
/// The days are walked in UTC, which is the same arithmetic
/// `ReportingDay.of` uses — so a range never skips or repeats a day at a
/// daylight-saving boundary the way local-time addition does.
final class ReadRange
    implements
        UseCase<
          ReadRangeCommand,
          Result<List<OperationTally>, ReportingFailure>
        > {
  /// Creates the use case.
  const ReadRange({required this._store});

  final TallyStore _store;

  @override
  Future<Result<List<OperationTally>, ReportingFailure>> call(
    ReadRangeCommand command,
  ) async {
    if (command.to.isBefore(command.from)) {
      return Failed(
        RangeInverted(from: command.from.value, to: command.to.value),
      );
    }

    final tallies = <OperationTally>[];
    for (final day in _days(command.from, command.to)) {
      final held = await _store.read(day.value);
      if (held case Failed(:final failure)) {
        return Failed(failure);
      }
      tallies.add(
        (held as Success<OperationTally, ReportingFailure>).value,
      );
    }
    return Success(tallies);
  }

  Iterable<ReportingDay> _days(ReportingDay from, ReportingDay to) sync* {
    var cursor = DateTime.parse('${from.value}T00:00:00Z');
    final last = DateTime.parse('${to.value}T00:00:00Z');
    while (!cursor.isAfter(last)) {
      yield ReportingDay.of(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
  }
}
