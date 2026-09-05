import 'package:core_kernel/core_kernel.dart';

import '../../entities/operation_tally.dart';
import '../../failures/reporting_failure.dart';
import '../../values/reporting_day.dart';

/// What the rest of the product may ask reporting for.
///
/// **Reads only.** Nothing outside this feature tells it what happened —
/// `reporting_core` builds its totals from domain events, and a `record`
/// method here would be an invitation for a screen to add a number the
/// operation never produced.
///
/// It speaks in `ReportingDay` because that is this feature's own type. There
/// is no `ActorId` on this surface at all: the tally is the operation's, not a
/// person's, and per-courier figures would be a different feature's question.
abstract interface class ReportingFacade {
  /// What [day] adds up to.
  Future<Result<OperationTally, ReportingFailure>> tallyFor(ReportingDay day);

  /// Every day between [from] and [to] inclusive, oldest first.
  ///
  /// Days with nothing on them are included as empty tallies. A chart with a
  /// gap where Sunday should be reads as missing data; a Sunday with zero on
  /// it reads as a Sunday.
  Future<Result<List<OperationTally>, ReportingFailure>> range({
    required ReportingDay from,
    required ReportingDay to,
  });
}
