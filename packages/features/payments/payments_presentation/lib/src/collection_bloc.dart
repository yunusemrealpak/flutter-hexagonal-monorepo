import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';

import 'collection_event.dart';
import 'collection_state.dart';

/// Drives the screen a courier takes money on.
///
/// It holds three ports and no implementations: `PaymentsFacade` to read what
/// is owed and to collect it, `SessionReader` to know who is collecting, and
/// `PermissionChecker` to know whether they may. All three arrive through the
/// constructor, exactly as they did when this was a `ChangeNotifier` — a
/// `Bloc` changes how state leaves a class, not how collaborators enter one.
///
/// **`canCollect` is scenario 6 in its third feature.** The screen asks
/// whether the signed-in actor holds `Permission.collectPayment` and learns
/// nothing else. `shipments_presentation_dispatcher` asks before bulk
/// assignment, `delivery_presentation` before recording a hand-over, and none
/// of the three knows anything about roles or grants.
///
/// **The amount is read, never typed.** It comes from `PaymentStatus`, so a
/// courier cannot collect a different number from the one the operation is
/// owed. A screen with a text field would be exactly where that difference got
/// in, and it would be indistinguishable from a typing mistake afterwards.
///
/// **The two transformers are the reason this is a `Bloc` and not a `Cubit`.**
/// They are policies about concurrent work, and a method call has nowhere to
/// carry one:
///
/// - `droppable()` on [CollectionSubmitted]. A second tap while the first
///   collection is in flight is ignored rather than queued. The
///   `ChangeNotifier` this replaced had no guard at all, and
///   `PaymentsFacade.collectOnDelivery` takes no idempotency key from here, so
///   two taps were two payments. This is the one behavioural fix in the
///   migration and it has a test of its own.
/// - `restartable()` on [CollectionRequested]. Asking about a second parcel
///   abandons the answer to the first, so a slow read cannot land after a fast
///   one and put the previous door's amount on screen.
///
/// [MethodChosen] is registered with the default `concurrent()` transformer,
/// because choosing cash after choosing card is not a race — it is a person
/// changing their mind, and the last one to arrive is the right answer.
final class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  /// Creates the bloc over its three ports.
  CollectionBloc({
    required this._payments,
    required this._session,
    required this._permissions,
  }) : super(const CollectionIdle()) {
    on<CollectionRequested>(_onRequested, transformer: restartable());
    on<MethodChosen>(_onMethodChosen);
    on<CollectionSubmitted>(_onSubmitted, transformer: droppable());
  }

  final PaymentsFacade _payments;
  final SessionReader _session;
  final PermissionChecker _permissions;

  /// Whether this actor may take money.
  ///
  /// Read on every build rather than held in the state. A permission can be
  /// revoked mid-shift, and a state that captured the answer when the screen
  /// opened would keep offering an action the operation has taken away. It is
  /// deliberately *not* a field of [CollectionState] for that reason: putting
  /// it there would make a stale copy of it part of what the bloc emits.
  bool get canCollect => _permissions.can(Permission.collectPayment);

  Future<void> _onRequested(
    CollectionRequested event,
    Emitter<CollectionState> emit,
  ) async {
    emit(const CollectionLoading());

    final status = await _payments.paymentStatusOf(event.shipment);

    emit(
      switch (status) {
        Success(value: Outstanding(:final amount)) => Owed(amount),
        // Settled, refunded and nothing-to-collect are one thing to a courier
        // standing at a door: there is nothing to do here.
        Success() => const NothingOwed(),
        Failed(:final failure) => CollectionFailed(failure),
      },
    );
  }

  void _onMethodChosen(MethodChosen event, Emitter<CollectionState> emit) {
    if (state case final Owed owed) {
      emit(owed.copyWith(method: event.method));
    }
  }

  /// Takes the money.
  ///
  /// Refuses locally when the actor may not collect. The use case does not
  /// check permissions — identity is not one of its collaborators — so a
  /// screen that offered the action to somebody without the grant would be the
  /// last thing between them and a recorded payment.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this.
  Future<void> _onSubmitted(
    CollectionSubmitted event,
    Emitter<CollectionState> emit,
  ) async {
    if (state case final Owed owed) {
      if (!canCollect) return;

      final courier = _session.current?.actor.id;
      if (courier == null) return;

      final collected = await _payments.collectOnDelivery(
        shipment: event.shipment,
        courier: courier,
        amount: owed.amount,
        method: owed.method,
      );

      emit(
        switch (collected) {
          Success(value: final attempt) => Collected(attempt),
          // The money is still owed and the courier is still at the door.
          // Dropping to a failure state would end a visit that has not
          // finished.
          Failed(:final failure) => owed.copyWith(refusal: failure),
        },
      );
    }
  }
}
