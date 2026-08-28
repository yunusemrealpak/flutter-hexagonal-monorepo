import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:reporting_api/reporting_api.dart';

import 'report_controller.dart';
import 'report_state.dart';
import 'reporting_strings.dart';

/// Where a dispatcher watches the day.
///
/// **No chart.** A chart is a component, and `design_system` does not have one
/// — deliberately, because the first chart in a design system is the decision
/// that shapes every chart after it, and this repository has no data to shape
/// it around. Rows and rates are what the numbers actually support.
final class ReportScreen extends StatelessWidget {
  /// Creates the screen over [controller].
  const ReportScreen({required this.controller, super.key});

  /// What drives it.
  final ReportController controller;

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `ReportingFailure`.
  @visibleForTesting
  static String describe(ReportingFailure failure) => switch (failure) {
    TallyUnavailable() => ReportingStrings.failureTallyUnavailable,
    RangeInverted() => ReportingStrings.failureRangeInverted,
    MalformedTally() => ReportingStrings.failureMalformed,
  };

  /// A rate as whole percentage points.
  ///
  /// Whole points, because a delivery rate quoted to two decimal places
  /// invites somebody to treat a change of 0.03 as news. A number rather than
  /// a string: where the per-cent sign goes is the app's question, and it is
  /// answered once per locale rather than once here.
  @visibleForTesting
  static int percent(double value) => (value * 100).round();

  /// How a day's rate should be drawn.
  ///
  /// The thresholds are reporting's, not the design system's. Eighty-five per
  /// cent being the line between "fine" and "look at this" is an operational
  /// fact about a courier network, and a component library that knew it would
  /// be a component library that had learned what a delivery is.
  @visibleForTesting
  static PeykIntent intentOfRate(double value) => switch (percent(value)) {
    >= 95 => PeykIntent.success,
    >= 85 => PeykIntent.neutral,
    >= 70 => PeykIntent.warning,
    _ => PeykIntent.danger,
  };

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(ReportingStrings.title),
      scrollable: true,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => switch (controller.state) {
          ReportIdle() || ReportLoading() => const PeykLoadingView(),
          // Not a failure. A courier opening a dispatcher's report has not hit
          // an error, they have hit a screen that is not theirs — and a retry
          // button would suggest otherwise.
          ReportForbidden() => PeykEmptyView(
            message: strings.resolve(ReportingStrings.forbidden),
          ),
          ReportReady(:final days, :final total, :final delivered) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PeykSection(
                title: strings.resolve(ReportingStrings.totalsSection),
                children: [
                  PeykText.display(
                    strings.resolve(
                      ReportingStrings.total,
                      arguments: {'count': total},
                    ),
                  ),
                  PeykText.body(
                    strings.resolve(
                      ReportingStrings.delivered,
                      arguments: {'count': delivered},
                    ),
                  ),
                ],
              ),
              const PeykGap.vertical(PeykGapSize.betweenGroups),
              PeykSection(
                title: strings.resolve(ReportingStrings.daysSection),
                children: [
                  for (final day in days) _DayRow(day: day),
                ],
              ),
            ],
          ),
          ReportFailed(:final failure) => PeykFailureView(
            message: strings.resolve(ReportScreen.describe(failure)),
            onRetry: () => unawaited(controller.retry()),
          ),
        },
      ),
    );
  }
}

/// One day's figures.
final class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final OperationTally day;

  @override
  Widget build(BuildContext context) {
    final rate = day.successRate;

    return PeykListRow(
      title: day.day.value,
      trailing: PeykChip(
        label: PeykStrings.of(context).resolve(
          ReportingStrings.dayRate,
          arguments: {
            'day': day.day.value,
            'rate': ReportScreen.percent(rate),
          },
        ),
        intent: ReportScreen.intentOfRate(rate),
      ),
    );
  }
}
