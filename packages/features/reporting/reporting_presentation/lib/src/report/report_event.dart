import 'package:reporting_api/reporting_api.dart';

/// What can be asked of the reporting board.
sealed class ReportEvent {
  const ReportEvent();
}

/// Read the totals for a range of days.
final class RangeRequested extends ReportEvent {
  /// Creates the event.
  const RangeRequested({required this.from, required this.to});

  /// The first day the report covers.
  final ReportingDay from;

  /// The last day it covers.
  final ReportingDay to;
}

/// Read the last range again.
///
/// Carries no range, deliberately. The screen never had one — an app decides
/// which days a report covers, and a widget that held them would be a widget
/// deciding what a dispatcher is looking at. The bloc remembers.
final class ReportRetried extends ReportEvent {
  /// Creates the event.
  const ReportRetried();
}
