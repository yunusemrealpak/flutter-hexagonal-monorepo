import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'incident_board_state.dart';

/// Drives the incident board and the report form beside it.
///
/// It holds two ports — `IncidentsFacade` and `PermissionChecker` — and no
/// implementation of either. The second is scenario 6 for the fourth time in
/// this workspace: the question "may this person report an incident" is asked
/// of identity and answered without this package learning what a role is.
final class IncidentBoardController extends ChangeNotifier {
  /// Creates the controller for one actor.
  IncidentBoardController({
    required this._incidents,
    required this._permissions,
    required this._actor,
  });

  final IncidentsFacade _incidents;
  final PermissionChecker _permissions;
  final ActorId _actor;

  IncidentBoardState _state = const BoardIdle();

  /// What the screen should be showing.
  IncidentBoardState get state => _state;

  /// Whether this actor may record an exception.
  ///
  /// Asked once and read by the widget, rather than asked inside `build`.
  /// A permission check in a build method runs on every frame and turns a
  /// question about authority into a question about rendering.
  bool get canReport => _permissions.can(Permission.reportIncident);

  /// Reads what is still open.
  Future<void> load() async {
    _emit(const BoardLoading());
    _emit(_settled(await _incidents.open()));
  }

  /// Records an exception and refreshes the board.
  ///
  /// Refuses without the permission rather than asking and being turned down.
  /// The screen has already hidden the control; this is the second half of the
  /// same check, and it is here because a controller is reachable from a route
  /// as well as from a button.
  Future<void> report({
    required IncidentCategory category,
    ShipmentId? shipmentId,
    String? note,
  }) async {
    if (!canReport) {
      return;
    }

    final reported = await _incidents.report(
      reportedBy: _actor,
      category: category,
      shipmentId: shipmentId,
      note: note,
    );
    if (reported case Failed(:final failure)) {
      _emit(BoardFailed(failure));
      return;
    }
    await load();
  }

  /// Closes one incident and refreshes the board.
  ///
  /// A re-read rather than a local removal, for the reason every other
  /// controller in this workspace gives: two dispatchers can be looking at one
  /// board, and a row removed optimistically would disagree with the log the
  /// moment the other one resolved something.
  Future<void> resolve(IncidentId id, String outcome) async {
    final resolved = await _incidents.resolve(id: id, outcome: outcome);
    if (resolved case Failed(:final failure)) {
      _emit(BoardFailed(failure));
      return;
    }
    await load();
  }

  IncidentBoardState _settled(
    Result<List<Incident>, IncidentsFailure> result,
  ) => switch (result) {
    Success(:final value) => BoardReady(value),
    Failed(:final failure) => BoardFailed(failure),
  };

  void _emit(IncidentBoardState next) {
    _state = next;
    notifyListeners();
  }
}
