import 'package:flutter/widgets.dart';
import 'package:reporting_api/reporting_api.dart';

import 'report_controller.dart';
import 'report_state.dart';

/// Where a dispatcher watches the day.
///
/// Deliberately plain: no chart, no colours, no typography. A chart is the
/// first thing `design_system` will bring in phase 7, and drawing one here
/// with hand-rolled painting would be a thing to delete rather than a thing to
/// restyle.
final class ReportScreen extends StatelessWidget {
  /// Creates the screen over [controller].
  const ReportScreen({required this.controller, super.key});

  /// What drives it.
  final ReportController controller;

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `ReportingFailure`.
  static String describe(ReportingFailure failure) => switch (failure) {
    TallyUnavailable() => 'The figures could not be read.',
    RangeInverted() => 'That range starts after it ends.',
    MalformedTally() => 'Some of the stored figures could not be read.',
  };

  /// Renders a rate as whole percentage points.
  ///
  /// Whole points, because a delivery rate quoted to two decimal places
  /// invites somebody to treat a change of 0.03 as news. No locale: the
  /// separator is the app's problem, in phase 7.
  static String rate(double value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => switch (controller.state) {
      ReportIdle() || ReportLoading() => const Text('reports.loading'),
      ReportForbidden() => const Text('reports.forbidden'),
      ReportReady(:final days, :final total, :final delivered) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('reports.total $total'),
          Text('reports.delivered $delivered'),
          for (final day in days)
            Text('${day.day.value} ${ReportScreen.rate(day.successRate)}'),
        ],
      ),
      ReportFailed(:final failure) => Text(ReportScreen.describe(failure)),
    },
  );
}
