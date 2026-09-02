import 'package:core_kernel/core_kernel.dart';

/// Why the operating system would not take a task.
///
/// Two cases, and deliberately not three. A `SchedulingUnsupported` for the
/// platforms with no background execution would read well and nothing could
/// construct it: the plugin's web and desktop implementations answer the call
/// rather than refusing it, so a caller cannot be told the difference and a
/// case nothing produces is a case every `switch` carries for nothing.
sealed class SchedulingFailure extends Failure {
  /// Creates the failure.
  const SchedulingFailure();
}

/// The platform declined, and said why in its own vocabulary.
///
/// [code] is the platform's, unmapped on purpose. iOS answers
/// `BGTaskSchedulerErrorDomain` codes — background refresh switched off, too
/// many pending tasks, an identifier the app never declared in its plist —
/// and each of those is a different thing for whoever reads the log. Mapping
/// them into a product word here would be this package deciding what they mean
/// to a product it knows nothing about.
final class SchedulingRefused extends SchedulingFailure {
  /// Creates the failure.
  const SchedulingRefused({required this.code, this.detail});

  /// The platform's own error code.
  final String code;

  /// Whatever else the platform said.
  final String? detail;

  @override
  String toString() =>
      'SchedulingRefused($code${detail == null ? '' : ': '
                '$detail'})';
}

/// Something else went wrong on the way to the scheduler.
final class SchedulingUnavailable extends SchedulingFailure {
  /// Creates the failure.
  const SchedulingUnavailable({required this.detail});

  /// What happened, for a log.
  final String detail;

  @override
  String toString() => 'SchedulingUnavailable($detail)';
}
