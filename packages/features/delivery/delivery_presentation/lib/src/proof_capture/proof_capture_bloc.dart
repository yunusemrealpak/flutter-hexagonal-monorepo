import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';

import 'proof_capture_event.dart';
import 'proof_capture_state.dart';

/// Drives the screen a courier taps *done* on.
///
/// It holds four ports and no implementations: `DeliveryExecution` to open an
/// attempt, `DeliverySettlement` to close one, `SessionReader` to know whose
/// afternoon it is, and `PermissionChecker` to know whether they may record a
/// hand-over at all. All four are declared in an `_api` package and all four
/// arrive through the constructor.
///
/// **Opening and closing are two ports because only one of them needs a
/// device.** `startAttempt` asks a geofence whether this device is at the
/// address; settling an attempt asks a store and a queue. A desk composes the
/// second and not the first, so this screen — which needs both — is a
/// courier's.
///
/// **`canComplete` is scenario 6.** The screen asks whether the signed-in
/// actor holds `Permission.completeDelivery` and never learns how identity
/// decided — not from a role, not from a grant, not from anything but the
/// answer. `shipments_presentation_dispatcher` asks the same port before it
/// renders bulk assignment; the pattern is the point, not the feature.
///
/// **There is no clock here, and there cannot be.** Section 2 allows a
/// presentation package `core_kernel`, `core_navigation`, contracts and the
/// Flutter SDK — not `core_ports`. So the proof takes its instant from the
/// evidence, through `ProofOfDelivery.from`, rather than from a time source
/// this layer is not allowed to hold.
///
/// **Two writes, two `droppable()` windows, and the second one spans two
/// events.** Arriving opens an attempt, so a second tap on the retry button
/// while the first is in flight would open a second attempt at the same door.
/// Settling closes one, and the two ways of closing it — a hand-over and a
/// failed visit — share a single `on<SettlementRequested>` because a
/// transformer governs one registration and no more: under two registrations,
/// tapping *delivered* and then *could not deliver* sends both to the port and
/// the domain answers the loser with `AttemptAlreadySettled`.
///
/// The evidence events carry no transformer at all. They are synchronous, they
/// touch no port, and a transformer over a handler that never suspends would
/// be a policy with nothing to decide.
final class ProofCaptureBloc
    extends Bloc<ProofCaptureEvent, ProofCaptureState> {
  /// Creates the bloc over its four ports.
  ProofCaptureBloc({
    required this._execution,
    required this._settlement,
    required this._session,
    required this._permissions,
  }) : super(const AwaitingArrival()) {
    on<ArrivalRequested>(_onArrival, transformer: droppable());
    on<RecipientNamed>(_onRecipientNamed);
    on<SignatureCaptured>(_onSignatureCaptured);
    on<PhotoCaptured>(_onPhotoCaptured);
    on<ScanCaptured>(_onScanCaptured);
    on<SettlementRequested>(_onSettlement, transformer: droppable());
  }

  final DeliveryExecution _execution;
  final DeliverySettlement _settlement;
  final SessionReader _session;
  final PermissionChecker _permissions;

  /// Whether this actor may record a hand-over.
  ///
  /// A getter on the bloc rather than a field on the state, and read on every
  /// build rather than cached. A permission can be revoked mid-shift, and a
  /// screen that answered from a value it captured when it opened would keep
  /// offering an action the operation has taken away. Putting it in the state
  /// would freeze it at the instant of the last emission, which is the same
  /// bug one emission later.
  bool get canComplete => _permissions.can(Permission.completeDelivery);

  /// Opens an attempt at the event's address.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this, and asking to deliver on
  /// nobody's behalf would be a request the operation has to answer with an
  /// error the user cannot act on.
  Future<void> _onArrival(
    ArrivalRequested event,
    Emitter<ProofCaptureState> emit,
  ) async {
    final courier = _session.current?.actor.id;
    if (courier == null) return;

    emit(const Arriving());

    final opened = await _execution.startAttempt(
      shipment: event.shipment,
      courier: courier,
      grade: event.grade,
    );

    emit(
      switch (opened) {
        Success(value: final attempt) => AtTheDoor(attempt),
        Failed(:final failure) => CaptureFailed(failure),
      },
    );
  }

  void _onRecipientNamed(
    RecipientNamed event,
    Emitter<ProofCaptureState> emit,
  ) {
    if (state case final AtTheDoor door) {
      // The notice is carried forward where the refusal is not. A refusal is
      // an answer to the completion this keystroke is part of; a blocked
      // camera permission is not, and it carries the settings button with it.
      // Watching the only way out vanish under their thumb is worse than
      // never offering it.
      emit(door.copyWith(recipientName: event.name, notice: door.notice));
    }
  }

  /// Takes a signature, or what came instead of one.
  ///
  /// The evidence arrives already built, and the two captures reach the app by
  /// different routes. A photograph is a device capability behind
  /// `platform/*`, which §1.1 does not give a presentation package. A
  /// signature needs no device at all — it is a `design_system` component and
  /// a `Clock` — and this layer still does not build one, because §1.1 does
  /// not give it `core_ports` either. Both end in the same place for different
  /// reasons: the app supplies the capture and this holds the result.
  void _onSignatureCaptured(
    SignatureCaptured event,
    Emitter<ProofCaptureState> emit,
  ) {
    if (state case final AtTheDoor door) {
      emit(
        switch (event.capture) {
          Success(:final value) => door.copyWith(signature: value),
          Failed(:final failure) => _noticed(door, failure),
        },
      );
    }
  }

  void _onPhotoCaptured(
    PhotoCaptured event,
    Emitter<ProofCaptureState> emit,
  ) {
    if (state case final AtTheDoor door) {
      emit(
        switch (event.capture) {
          Success(:final value) => door.copyWith(photo: value),
          Failed(:final failure) => _noticed(door, failure),
        },
      );
    }
  }

  void _onScanCaptured(ScanCaptured event, Emitter<ProofCaptureState> emit) {
    if (state case final AtTheDoor door) {
      emit(door.copyWith(scan: event.scan));
    }
  }

  /// Puts a refusal on the door state, or clears one.
  ///
  /// A courier who backed out is shown nothing — that is what
  /// [CaptureDeclined] is for — and clearing rather than keeping the previous
  /// notice matters: pressing the camera again and dismissing it is a courier
  /// saying they are done with the question.
  AtTheDoor _noticed(AtTheDoor door, CaptureRefusal refusal) =>
      door.copyWith(notice: refusal is CaptureDeclined ? null : refusal);

  Future<void> _onSettlement(
    SettlementRequested event,
    Emitter<ProofCaptureState> emit,
  ) async {
    if (state case final AtTheDoor door) {
      switch (event) {
        case HandoverRecorded():
          await _complete(door, emit);
        case NonDeliveryRecorded(:final reason):
          await _fail(door, reason, emit);
      }
    }
  }

  /// Closes the attempt with what has been captured.
  ///
  /// Refuses locally when the actor may not record a hand-over. The use case
  /// does not check permissions — identity is not one of its collaborators —
  /// so a screen that offered the action to somebody without the grant would
  /// be the last thing between them and a recorded delivery.
  Future<void> _complete(
    AtTheDoor door,
    Emitter<ProofCaptureState> emit,
  ) async {
    if (!canComplete) return;

    final Recipient recipient;
    switch (Recipient.named(door.recipientName)) {
      case Failed(:final failure):
        emit(door.copyWith(refusal: failure));
        return;
      case Success(:final value):
        recipient = value;
    }

    final ProofOfDelivery proof;
    switch (ProofOfDelivery.from(
      recipient: recipient,
      signature: door.signature,
      photo: door.photo,
      scan: door.scan,
    )) {
      case Failed(:final failure):
        emit(door.copyWith(refusal: failure));
        return;
      case Success(:final value):
        proof = value;
    }

    final settled = await _settlement.completeWithProof(
      attempt: door.attempt,
      proof: proof,
    );

    emit(
      switch (settled) {
        Success(value: final attempt) => Settled(attempt),
        // The attempt is still open and still correct — the domain declined
        // to close it. Dropping to a failure state would send a courier back
        // to the start of a hand-over they are halfway through.
        Failed(:final failure) => door.copyWith(refusal: failure),
      },
    );
  }

  /// Closes the attempt without a hand-over.
  ///
  /// Needs no permission check. Recording that a delivery did not happen is
  /// something every courier standing at a door may do, and gating it would
  /// leave the visit unrecorded rather than leaving it undone.
  Future<void> _fail(
    AtTheDoor door,
    NonDeliveryReason reason,
    Emitter<ProofCaptureState> emit,
  ) async {
    final settled = await _settlement.failWithReason(
      attempt: door.attempt,
      reason: reason,
    );

    emit(
      switch (settled) {
        Success(value: final attempt) => Settled(attempt),
        Failed(:final failure) => door.copyWith(refusal: failure),
      },
    );
  }
}
