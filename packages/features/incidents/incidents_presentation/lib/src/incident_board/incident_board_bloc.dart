import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';

import 'incident_board_event.dart';
import 'incident_board_state.dart';

/// Drives the incident board and the report form beside it.
///
/// It holds two ports — `IncidentsFacade` and `PermissionChecker` — and no
/// implementation of either. The second is scenario 6 for the fourth time in
/// this workspace: the question "may this person report an incident" is asked
/// of identity and answered without this package learning what a role is.
///
/// **Three events, three transformers, and the difference between them is the
/// lesson.** They are not degrees of strictness; they answer different
/// questions about what a repeated intention means.
///
/// - `restartable()` on [BoardRequested]. A newer read of the board makes an
///   older one worthless, and finishing the older one would put a stale board
///   on screen after a fresh one.
/// - `droppable()` on [IncidentReported]. A second tap on *report* is the same
///   exception being recorded twice, and `IncidentsFacade.report` takes no
///   idempotency key — so without this, a double tap on a slow connection is
///   two rows on a dispatcher's board for one thing that happened once.
/// - `sequential()` on [IncidentResolved]. Every one of these is a *different*
///   incident being closed, so none of them may be dropped; what must not
///   happen is two of them re-reading the board at once, because the second
///   read can land before the first and undo it on screen. Queued, not
///   discarded.
///
/// Dropping a resolve the way a report is dropped would be the defect this
/// arrangement exists to avoid: a dispatcher working quickly down a board
/// would find that every second row they closed had silently not been.
final class IncidentBoardBloc
    extends Bloc<IncidentBoardEvent, IncidentBoardState> {
  /// Creates the bloc for one actor.
  IncidentBoardBloc({
    required this._incidents,
    required this._permissions,
    required this._actor,
  }) : super(const BoardIdle()) {
    on<BoardRequested>(_onRequested, transformer: restartable());
    on<IncidentReported>(_onReported, transformer: droppable());
    on<IncidentResolved>(_onResolved, transformer: sequential());
  }

  final IncidentsFacade _incidents;
  final PermissionChecker _permissions;
  final ActorId _actor;

  /// Whether this actor may record an exception.
  ///
  /// Read from the bloc rather than carried in the state. A permission the
  /// operation revokes mid-shift must not be answered from a value the screen
  /// captured when it opened.
  bool get canReport => _permissions.can(Permission.reportIncident);

  Future<void> _onRequested(
    BoardRequested event,
    Emitter<IncidentBoardState> emit,
  ) async {
    emit(const BoardLoading());
    await _read(emit);
  }

  /// Records an exception and re-reads the board.
  ///
  /// Refuses without the permission rather than asking and being turned down.
  /// The screen has already hidden the control; this is the second half of the
  /// same check, and it is here because an event is reachable from a route as
  /// well as from a button.
  Future<void> _onReported(
    IncidentReported event,
    Emitter<IncidentBoardState> emit,
  ) async {
    if (!canReport) return;

    final reported = await _incidents.report(
      reportedBy: _actor,
      category: event.category,
      shipmentId: event.shipmentId,
      note: event.note,
    );
    if (reported case Failed(:final failure)) {
      emit(BoardFailed(failure));
      return;
    }
    await _read(emit);
  }

  /// Closes one incident and re-reads the board.
  ///
  /// A re-read rather than a local removal, for the reason every other screen
  /// in this workspace gives: two dispatchers can be looking at one board, and
  /// a row removed optimistically would disagree with the log the moment the
  /// other one resolved something.
  Future<void> _onResolved(
    IncidentResolved event,
    Emitter<IncidentBoardState> emit,
  ) async {
    final resolved = await _incidents.resolve(
      id: event.id,
      outcome: event.outcome,
    );
    if (resolved case Failed(:final failure)) {
      emit(BoardFailed(failure));
      return;
    }
    await _read(emit);
  }

  Future<void> _read(Emitter<IncidentBoardState> emit) async {
    emit(
      switch (await _incidents.open()) {
        Success(:final value) => BoardReady(value),
        Failed(:final failure) => BoardFailed(failure),
      },
    );
  }
}
