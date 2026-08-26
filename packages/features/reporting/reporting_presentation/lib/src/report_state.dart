import 'package:reporting_api/reporting_api.dart';

/// What the reporting board can be showing.
sealed class ReportState {
  const ReportState();
}

/// Nothing has been asked for yet.
final class ReportIdle extends ReportState {
  /// Creates the state.
  const ReportIdle();
}

/// The totals are being read.
final class ReportLoading extends ReportState {
  /// Creates the state.
  const ReportLoading();
}

/// The totals arrived.
final class ReportReady extends ReportState {
  /// Creates the state.
  const ReportReady(this.days);

  /// One tally per day in the range, oldest first.
  final List<OperationTally> days;

  /// How many parcels finished across the whole range.
  ///
  /// Summed here rather than on `OperationTally`, because a total across days
  /// is a question about a *range* and the entity is about one day. Putting it
  /// on the entity would mean a method that only makes sense on a list.
  int get total => days.fold(0, (sum, day) => sum + day.total);

  /// How many were handed over across the whole range.
  int get delivered => days.fold(0, (sum, day) => sum + day.delivered);
}

/// The totals could not be read, or the range made no sense.
final class ReportFailed extends ReportState {
  /// Creates the state.
  const ReportFailed(this.failure);

  /// What went wrong, in reporting's own words.
  final ReportingFailure failure;
}

/// This actor may not see reports at all.
///
/// A state rather than an empty board, because the two mean opposite things: a
/// dispatcher with an empty board is looking at a quiet morning, and a courier
/// who reached this screen is looking at something that is not theirs to see.
final class ReportForbidden extends ReportState {
  /// Creates the state.
  const ReportForbidden();
}
