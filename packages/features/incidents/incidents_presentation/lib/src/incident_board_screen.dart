import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:incidents_api/incidents_api.dart';

import 'incident_board_controller.dart';
import 'incident_board_state.dart';
import 'incidents_strings.dart';

/// Where a dispatcher works down what is still open.
final class IncidentBoardScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const IncidentBoardScreen({required this.controller, super.key});

  /// What drives it.
  final IncidentBoardController controller;

  @override
  State<IncidentBoardScreen> createState() => _IncidentBoardScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `IncidentsFailure`, which is the point of it being
  /// sealed.
  @visibleForTesting
  static String describe(IncidentsFailure failure) => switch (failure) {
    IncidentLogUnavailable() => IncidentsStrings.failureLogUnavailable,
    IncidentMissing() => IncidentsStrings.failureMissing,
    IncidentNotInState() => IncidentsStrings.failureNotInState,
    MalformedIncident() => IncidentsStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(IncidentsFailure failure) =>
      switch (failure) {
        IncidentNotInState(:final attempted) => {'attempted': attempted},
        MalformedIncident(:final field) => {'field': field},
        IncidentLogUnavailable() || IncidentMissing() => const {},
      };

  /// How loudly a severity should be drawn.
  ///
  /// This is the mapping `design_system` deliberately cannot make. A component
  /// knows what `danger` looks like; only `incidents` knows that a critical
  /// incident is one. It is the reason `IncidentSeverity` exists as its own
  /// taxonomy rather than borrowing delivery's `NonDeliveryReason` — that
  /// union answers why a visit ended, and this one answers how fast somebody
  /// has to move.
  @visibleForTesting
  static PeykIntent intentOf(IncidentSeverity severity) => switch (severity) {
    IncidentSeverity.routine => PeykIntent.info,
    IncidentSeverity.urgent => PeykIntent.warning,
    IncidentSeverity.critical => PeykIntent.danger,
  };
}

class _IncidentBoardScreenState extends State<IncidentBoardScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(IncidentsStrings.boardTitle),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          BoardIdle() || BoardLoading() => const PeykLoadingView(),
          // An empty board is its own view. A screen with nothing on it reads
          // as a screen that failed to load, and a dispatcher would refresh it.
          BoardReady(:final incidents) when incidents.isEmpty => PeykEmptyView(
            message: strings.resolve(IncidentsStrings.boardClear),
          ),
          BoardReady(:final incidents) => ListView.builder(
            itemCount: incidents.length,
            itemBuilder: (context, index) => _Row(incident: incidents[index]),
          ),
          BoardFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              IncidentBoardScreen.describe(failure),
              arguments: IncidentBoardScreen.argumentsFor(failure),
            ),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
}

/// One incident on the board.
///
/// Severity is a chip rather than a semantics label, and that is the change
/// phase 6 said it was waiting for: severity is the thing a dispatcher reads
/// first, and until the design system existed the only honest way to render it
/// was a word a screen reader could hear and an eye could not find.
///
/// The chip carries its own word as well as its colour. A board where urgency
/// is only a hue is a board one dispatcher in twelve cannot sort.
class _Row extends StatelessWidget {
  const _Row({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykListRow(
      title: strings.resolve(IncidentsStrings.category(incident.category)),
      trailing: PeykChip(
        label: strings.resolve(IncidentsStrings.severity(incident.severity)),
        intent: IncidentBoardScreen.intentOf(incident.severity),
      ),
    );
  }
}
