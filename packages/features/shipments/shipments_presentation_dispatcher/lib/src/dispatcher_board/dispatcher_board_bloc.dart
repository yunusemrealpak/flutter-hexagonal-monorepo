import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'dispatcher_board_event.dart';
import 'dispatcher_board_state.dart';

/// Drives the dispatcher's board.
///
/// This is scenario 6 of the architecture, and the whole of it is the
/// `PermissionChecker` in the constructor. The board asks *can this actor
/// bulk-assign?* and gets a `bool`. It does not know that identity has roles,
/// that a role carries a `PermissionSet`, that an actor can hold a personal
/// grant, or that any of it is decided by a class called `Actor`. If identity
/// replaced all of that tomorrow, this file would not change.
///
/// The port is also the smallest thing that answers the question. Identity
/// publishes `IdentityFacade` too, and handing the board that instead would
/// give a screen whose job is drawing a table the ability to sign the user
/// out.
///
/// **Three registrations, three policies.** Reading the board is
/// `restartable()`, because a newer read makes an older one worthless.
/// Fetching the next page is `droppable()` — that transformer *is* the
/// in-flight guard the controller used to write by hand, and without it a
/// scrolled board fetches and appends the same page twice. Assigning a
/// selection is `droppable()` for the reason a payment is: two taps on
/// *assign eight parcels* are one dispatcher asking once.
///
/// Ticking a row carries no transformer at all. It touches no port and never
/// suspends, so a policy over it would have nothing to decide.
final class DispatcherBoardBloc
    extends Bloc<DispatcherBoardEvent, DispatcherBoardState> {
  /// Creates the bloc over its ports.
  DispatcherBoardBloc({
    required this._shipments,
    required this._permissions,
    required this._session,
  }) : super(const BoardIdle()) {
    on<BoardRequested>(_onRequested, transformer: restartable());
    on<MoreRequested>(_onMoreRequested, transformer: droppable());
    on<RowToggled>(_onRowToggled);
    on<SelectionAssigned>(_onSelectionAssigned, transformer: droppable());
  }

  final ShipmentsFacade _shipments;
  final PermissionChecker _permissions;
  final SessionReader _session;

  /// Whether the bulk-assign action may be offered at all.
  ///
  /// Asked before the button is rendered rather than when it is pressed. A
  /// button that appears and then refuses is a button that teaches a
  /// dispatcher to distrust the screen; the server checks again anyway,
  /// because a permission check in a client is a courtesy and not a control.
  ///
  /// A getter on the bloc rather than a field on the state, for the reason
  /// `ProofCaptureBloc.canComplete` is one: in the state it would be frozen at
  /// the instant of the last emission, and a grant can be revoked mid-shift.
  bool get canBulkAssign => _permissions.can(Permission.bulkAssignShipments);

  /// Whether a single assignment may be offered.
  ///
  /// A separate permission from [canBulkAssign], because the blast radius of
  /// the two differs by an order of magnitude. A supervisor who may reassign
  /// one parcel is not thereby allowed to reassign a depot.
  bool get canAssign => _permissions.can(Permission.assignShipment);

  Future<void> _onRequested(
    BoardRequested event,
    Emitter<DispatcherBoardState> emit,
  ) async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;

    emit(const BoardLoading());

    const first = PageRequest();
    final board = await _shipments.manifestFor(actor, page: first);
    emit(
      switch (board) {
        Success(value: final page) => BoardReady(
          rows: page.items,
          resume: first.following(page),
        ),
        Failed(:final failure) => BoardFailed(failure),
      },
    );
  }

  /// Fetches the page after the one on screen, keeping the ticks.
  ///
  /// Does nothing when there is nothing left, and nothing while a fetch is
  /// already out — the second of those is the transformer rather than a check
  /// written here.
  Future<void> _onMoreRequested(
    MoreRequested event,
    Emitter<DispatcherBoardState> emit,
  ) async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;
    if (state case final BoardReady showing) {
      final resume = showing.resume;
      if (resume == null) return;

      emit(showing.copyWith(loadingMore: true));

      final board = await _shipments.manifestFor(actor, page: resume);
      emit(
        switch (board) {
          Success(value: final page) => showing.appending(
            page.items,
            resume: resume.following(page),
          ),
          // The rows and the ticks both survive. Dropping to `BoardFailed`
          // would throw away a selection somebody assembled across two pages
          // because the third did not arrive.
          Failed(:final failure) => showing.copyWith(moreFailure: failure),
        },
      );
    }
  }

  void _onRowToggled(RowToggled event, Emitter<DispatcherBoardState> emit) {
    if (state case final BoardReady showing) {
      final selection = {...showing.selected};
      if (!selection.remove(event.shipmentId)) {
        selection.add(event.shipmentId);
      }
      emit(showing.withSelection(selection));
    }
  }

  /// Assigns every ticked shipment to the event's courier.
  ///
  /// Refuses without asking the operation when the actor may not bulk-assign.
  /// The check is here rather than only on the button because a bloc is
  /// reachable from a keyboard shortcut, a deep link and a test, and a rule
  /// that lives on a widget is a rule those three do not have.
  ///
  /// A failure stops the walk and lands on the state beside the rows. It used
  /// to be answered to the caller, and there was no caller — an app that wants
  /// to know what happened reads the board it is already rendering.
  Future<void> _onSelectionAssigned(
    SelectionAssigned event,
    Emitter<DispatcherBoardState> emit,
  ) async {
    if (!canBulkAssign) return;
    if (state case final BoardReady showing) {
      for (final id in showing.selected) {
        // A switch rather than a fold with a throw in the failure branch. Rule
        // A5 forbids a second failure channel a caller's type does not
        // mention, and this one has none at all.
        switch (ShipmentId.parse(id)) {
          case Failed(:final failure):
            emit(showing.copyWith(assignFailure: failure));
            return;
          case Success(value: final shipmentId):
            final assigned = await _shipments.assign(
              id: shipmentId,
              courier: event.courier,
            );
            if (assigned case Failed(:final failure)) {
              emit(showing.copyWith(assignFailure: failure));
              return;
            }
        }
      }

      add(const BoardRequested());
    }
  }
}
