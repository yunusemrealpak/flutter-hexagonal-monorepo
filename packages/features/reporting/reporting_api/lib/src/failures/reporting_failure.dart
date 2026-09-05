import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the reporting ports.
sealed class ReportingFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const ReportingFailure();
}

/// The running totals could not be read or written.
final class TallyUnavailable extends ReportingFailure {
  /// Records that the store did not answer, with [detail] for the log.
  const TallyUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'TallyUnavailable(${detail ?? 'no detail'})';
}

/// A range was asked for that does not describe any days.
///
/// Its own case because a dispatcher can produce it from a date picker in one
/// tap, and "from Friday to Monday" deserves a sentence rather than an empty
/// chart nobody can explain.
final class RangeInverted extends ReportingFailure {
  /// Records that [from] is after [to].
  const RangeInverted({required this.from, required this.to});

  /// The start that was asked for.
  final String from;

  /// The end that was asked for.
  final String to;

  @override
  String toString() => 'RangeInverted($from > $to)';
}

/// A value a tally carries was refused at construction.
final class MalformedTally extends ReportingFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedTally({required this.field, required this.reason});

  /// Which part refused its value.
  final String field;

  /// Why it was refused.
  final String reason;

  @override
  String toString() => 'MalformedTally($field: $reason)';
}
