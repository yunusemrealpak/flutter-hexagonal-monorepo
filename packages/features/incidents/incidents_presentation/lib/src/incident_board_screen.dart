import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:incidents_api/incidents_api.dart';

import 'incident_board_controller.dart';
import 'incident_board_state.dart';

/// Where a dispatcher works down what is still open.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7 — which matters more here
/// than on most screens, because severity is the thing a dispatcher reads
/// first and colour is how they will eventually read it.
final class IncidentBoardScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const IncidentBoardScreen({required this.controller, super.key});

  /// What drives it.
  final IncidentBoardController controller;

  @override
  State<IncidentBoardScreen> createState() => _IncidentBoardScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `IncidentsFailure`, which is the point of it being
  /// sealed.
  static String describe(IncidentsFailure failure) => switch (failure) {
    IncidentLogUnavailable() => 'The incident log could not be read.',
    IncidentMissing() => 'That incident is no longer open.',
    IncidentNotInState(:final attempted) =>
      'This incident cannot be $attempted now.',
    MalformedIncident(:final field) => 'Something is wrong with the $field.',
  };
}

class _IncidentBoardScreenState extends State<IncidentBoardScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      BoardIdle() || BoardLoading() => const Text('incidents.loading'),
      // An empty board is its own line. A screen with nothing on it reads as a
      // screen that failed to load, and a dispatcher would refresh it.
      BoardReady(:final incidents) when incidents.isEmpty => const Text(
        'incidents.clear',
      ),
      BoardReady(:final incidents) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final incident in incidents) _Row(incident: incident),
        ],
      ),
      BoardFailed(:final failure) => Text(
        IncidentBoardScreen.describe(failure),
      ),
    },
  );
}

/// One incident on the board.
///
/// The label is a key with the severity appended, not a sentence: the strings
/// belong to the app's localisation, which arrives in phase 7.
class _Row extends StatelessWidget {
  const _Row({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'incidents.severity.${incident.severity.name}',
    child: Text('incidents.category.${incident.category.name}'),
  );
}
