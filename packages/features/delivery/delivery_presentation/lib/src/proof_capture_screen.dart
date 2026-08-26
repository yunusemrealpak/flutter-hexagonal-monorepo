import 'dart:async';

import 'package:delivery_api/delivery_api.dart';
import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'proof_capture_controller.dart';
import 'proof_capture_state.dart';

/// Where a courier records what happened at the door.
///
/// **The complete action is behind a permission**, asked of `identity_api`'s
/// `PermissionChecker` and answered without this package learning anything
/// about roles or grants. That is scenario 6, in the second feature that needs
/// it; `shipments_presentation_dispatcher` asks the same port before it
/// renders bulk assignment.
///
/// **The camera arrives as a callback.** Capturing a signature or a photograph
/// means `platform/media_capture`, and section 2 forbids a presentation
/// package from depending on `platform/*` at all. So the app supplies the
/// capture, this screen offers the button, and the evidence comes back as a
/// value from `delivery_api`. An app that has no camera passes nothing and the
/// button is not drawn.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7, and inventing them here
/// would mean deleting them then.
final class ProofCaptureScreen extends StatefulWidget {
  /// Creates the screen over [controller], for [shipment].
  const ProofCaptureScreen({
    required this.controller,
    required this.shipment,
    this.grade = DeliveryGrade.standard,
    this.onCaptureSignature,
    this.onCapturePhoto,
    super.key,
  });

  /// What drives it.
  final ProofCaptureController controller;

  /// Which parcel this visit is about.
  final ShipmentId shipment;

  /// How much proof it is worth.
  ///
  /// Supplied by whoever already had the manifest row in hand. Delivery never
  /// reads a `Shipment` to work this out — section 2.1 — and this parameter is
  /// where the translation between the two features' vocabularies happens.
  final DeliveryGrade grade;

  /// Opens whatever this app captures signatures with.
  final Future<SignatureCapture?> Function()? onCaptureSignature;

  /// Opens whatever this app takes photographs with.
  final Future<PhotoEvidence?> Function()? onCapturePhoto;

  @override
  State<ProofCaptureScreen> createState() => _ProofCaptureScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Static and public so that a test can assert on the sentence without
  /// pumping a widget tree. Exhaustive over `DeliveryFailure`, which is the
  /// point of it being sealed: the day delivery learns a new way to fail, this
  /// stops compiling instead of quietly showing a courier the wrong sentence.
  static String describe(DeliveryFailure failure) => switch (failure) {
    OutsideDeliveryArea(:final metresAway) =>
      'You are ${metresAway.round()}m from the address.',
    DeliveryPositionUnavailable() =>
      'Your position could not be read. Move outside and try again.',
    ProofInsufficient(:final missing) =>
      'This parcel needs ${missing.join(' and ')}.',
    AttemptAlreadySettled() => 'This visit has already been recorded.',
    ProofStoreUnavailable() => 'The evidence could not be saved.',
    ProofNotFound() => 'That evidence is not on this device.',
    MediaTooLarge() => 'That photograph is too big. Take another.',
    DeliveryUnavailable() => 'This could not be queued. Try again.',
    MalformedDeliveryValue(:final field) => 'Something is wrong with $field.',
  };
}

class _ProofCaptureScreenState extends State<ProofCaptureScreen> {
  @override
  void initState() {
    super.initState();
    // initState cannot be async, and the arrival is genuinely
    // fire-and-forget: its result reaches the screen through the controller's
    // notification rather than through this call.
    unawaited(
      widget.controller.arrive(
        shipment: widget.shipment,
        grade: widget.grade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      AwaitingArrival() || Arriving() => const Center(
        child: Text('Checking you are at the address'),
      ),
      final AtTheDoor state => _Door(
        state: state,
        canComplete: widget.controller.canComplete,
        onRecipient: widget.controller.recipientIs,
        onSignature: widget.onCaptureSignature == null
            ? null
            : () => unawaited(_capture(_Kind.signature)),
        onPhoto: widget.onCapturePhoto == null
            ? null
            : () => unawaited(_capture(_Kind.photo)),
        onComplete: () => unawaited(widget.controller.complete()),
        onFail: () => unawaited(
          widget.controller.couldNotDeliver(
            const NonDeliveryReason.recipientAbsent(),
          ),
        ),
      ),
      Settled() => const Center(child: Text('Recorded')),
      CaptureFailed(:final failure) => Center(
        child: Text(ProofCaptureScreen.describe(failure)),
      ),
    },
  );

  Future<void> _capture(_Kind kind) async {
    switch (kind) {
      case _Kind.signature:
        final signature = await widget.onCaptureSignature!();
        if (signature != null) widget.controller.addSignature(signature);
      case _Kind.photo:
        final photo = await widget.onCapturePhoto!();
        if (photo != null) widget.controller.addPhoto(photo);
    }
  }
}

enum _Kind { signature, photo }

final class _Door extends StatelessWidget {
  const _Door({
    required this.state,
    required this.canComplete,
    required this.onRecipient,
    required this.onComplete,
    required this.onFail,
    this.onSignature,
    this.onPhoto,
  });

  final AtTheDoor state;
  final bool canComplete;
  final void Function(String) onRecipient;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final VoidCallback? onSignature;
  final VoidCallback? onPhoto;

  @override
  Widget build(BuildContext context) {
    final signature = onSignature;
    final photo = onPhoto;
    final refusal = state.refusal;

    return ListView(
      children: [
        Text('Delivering ${state.attempt.shipment.value}'),
        if (state.missing.isNotEmpty)
          // The rule, read from ProofPolicy rather than restated here. A
          // second copy would tell a courier they were finished on the day the
          // policy changed and the use case disagreed.
          Text('Still needed: ${state.missing.map((k) => k.name).join(', ')}'),
        for (final kind in state.carries) Text('Captured: ${kind.name}'),
        EditableText(
          controller: TextEditingController(text: state.recipientName),
          focusNode: FocusNode(),
          style: const TextStyle(),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF000000),
          onChanged: onRecipient,
        ),
        if (signature != null)
          GestureDetector(onTap: signature, child: const Text('Add signature')),
        if (photo != null)
          GestureDetector(onTap: photo, child: const Text('Add photo')),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions — identity is not one of its
        // collaborators — so this is the last thing between them and a
        // recorded delivery.
        if (canComplete && state.isComplete)
          GestureDetector(onTap: onComplete, child: const Text('Delivered')),
        GestureDetector(onTap: onFail, child: const Text('Could not deliver')),
        if (refusal != null) Text(ProofCaptureScreen.describe(refusal)),
      ],
    );
  }
}
