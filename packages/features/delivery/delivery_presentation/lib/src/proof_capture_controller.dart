import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

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
final class ProofCaptureController extends ChangeNotifier {
  /// Creates the controller over its four ports.
  ProofCaptureController({
    required this._execution,
    required this._settlement,
    required this._session,
    required this._permissions,
  });

  final DeliveryExecution _execution;
  final DeliverySettlement _settlement;
  final SessionReader _session;
  final PermissionChecker _permissions;

  ProofCaptureState _state = const AwaitingArrival();

  /// What the screen should be showing.
  ProofCaptureState get state => _state;

  /// Whether this actor may record a hand-over.
  ///
  /// Read on every build rather than cached. A permission can be revoked
  /// mid-shift, and a screen that answered from a value it captured when it
  /// opened would keep offering an action the operation has taken away.
  bool get canComplete => _permissions.can(Permission.completeDelivery);

  /// Opens an attempt at [shipment]'s address.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this, and asking to deliver on
  /// nobody's behalf would be a request the operation has to answer with an
  /// error the user cannot act on.
  Future<void> arrive({
    required ShipmentId shipment,
    DeliveryGrade grade = DeliveryGrade.standard,
  }) async {
    final courier = _session.current?.actor.id;
    if (courier == null) return;

    _emit(const Arriving());

    final opened = await _execution.startAttempt(
      shipment: shipment,
      courier: courier,
      grade: grade,
    );

    _emit(
      switch (opened) {
        Success(value: final attempt) => AtTheDoor(attempt),
        Failed(:final failure) => CaptureFailed(failure),
      },
    );
  }

  /// Records who is at the door.
  void recipientIs(String name) {
    if (_state case final AtTheDoor state) {
      // The notice is carried forward where the refusal is not. A refusal is
      // an answer to the completion this keystroke is part of; a blocked
      // camera permission is not, and it carries the settings button with it.
      // Watching the only way out vanish under their thumb is worse than
      // never offering it.
      _emit(state.copyWith(recipientName: name, notice: state.notice));
    }
  }

  /// Adds a signature to what has been captured.
  ///
  /// The evidence arrives already built. Capturing it means a camera or a
  /// signature pad, both of which live behind `platform/*`, and a presentation
  /// package may not depend on one — so the app supplies the capture and this
  /// layer holds the result.
  void addSignature(SignatureCapture signature) {
    if (_state case final AtTheDoor state) {
      _emit(state.copyWith(signature: signature));
    }
  }

  /// Adds a photograph.
  void addPhoto(PhotoEvidence photo) {
    if (_state case final AtTheDoor state) {
      _emit(state.copyWith(photo: photo));
    }
  }

  /// Adds a scan.
  void addScan(ScanEvidence scan) {
    if (_state case final AtTheDoor state) {
      _emit(state.copyWith(scan: scan));
    }
  }

  /// Records what came back when this app was asked for a photograph.
  ///
  /// The four-case answer `ProofCaptureScreen.onCapturePhoto` now gives. It
  /// used to be a `PhotoEvidence?`, which made a camera switched off in the
  /// system settings indistinguishable from a courier who changed their mind —
  /// so the one outcome with a way out of it was the one nothing offered a way
  /// out of.
  void capturedPhoto(Result<PhotoEvidence, CaptureRefusal> capture) {
    switch (capture) {
      case Success(:final value):
        addPhoto(value);
      case Failed(:final failure):
        _noticed(failure);
    }
  }

  /// Records what came back when this app was asked for a signature.
  void capturedSignature(Result<SignatureCapture, CaptureRefusal> capture) {
    switch (capture) {
      case Success(:final value):
        addSignature(value);
      case Failed(:final failure):
        _noticed(failure);
    }
  }

  /// Puts a refusal on the door state, or clears one.
  ///
  /// A courier who backed out is shown nothing — that is what
  /// [CaptureDeclined] is for — and clearing rather than keeping the previous
  /// notice matters: pressing the camera again and dismissing it is a courier
  /// saying they are done with the question.
  void _noticed(CaptureRefusal refusal) {
    if (_state case final AtTheDoor state) {
      _emit(
        state.copyWith(notice: refusal is CaptureDeclined ? null : refusal),
      );
    }
  }

  /// Closes the attempt with what has been captured.
  ///
  /// Refuses locally when the actor may not record a hand-over. The use case
  /// does not check permissions — identity is not one of its collaborators —
  /// so a screen that offered the action to somebody without the grant would
  /// be the last thing between them and a recorded delivery.
  Future<void> complete() async {
    if (_state case final AtTheDoor state) {
      if (!canComplete) return;

      final Recipient recipient;
      switch (Recipient.named(state.recipientName)) {
        case Failed(:final failure):
          _emit(state.copyWith(refusal: failure));
          return;
        case Success(:final value):
          recipient = value;
      }

      final ProofOfDelivery proof;
      switch (ProofOfDelivery.from(
        recipient: recipient,
        signature: state.signature,
        photo: state.photo,
        scan: state.scan,
      )) {
        case Failed(:final failure):
          _emit(state.copyWith(refusal: failure));
          return;
        case Success(:final value):
          proof = value;
      }

      final settled = await _settlement.completeWithProof(
        attempt: state.attempt,
        proof: proof,
      );

      _emit(
        switch (settled) {
          Success(value: final attempt) => Settled(attempt),
          // The attempt is still open and still correct — the domain declined
          // to close it. Dropping to a failure state would send a courier back
          // to the start of a hand-over they are halfway through.
          Failed(:final failure) => state.copyWith(refusal: failure),
        },
      );
    }
  }

  /// Closes the attempt without a hand-over.
  ///
  /// Needs no permission check. Recording that a delivery did not happen is
  /// something every courier standing at a door may do, and gating it would
  /// leave the visit unrecorded rather than leaving it undone.
  Future<void> couldNotDeliver(NonDeliveryReason reason) async {
    if (_state case final AtTheDoor state) {
      final settled = await _settlement.failWithReason(
        attempt: state.attempt,
        reason: reason,
      );

      _emit(
        switch (settled) {
          Success(value: final attempt) => Settled(attempt),
          Failed(:final failure) => state.copyWith(refusal: failure),
        },
      );
    }
  }

  void _emit(ProofCaptureState next) {
    _state = next;
    notifyListeners();
  }
}
