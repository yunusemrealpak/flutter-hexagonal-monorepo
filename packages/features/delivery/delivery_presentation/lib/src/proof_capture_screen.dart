import 'dart:async';

import 'package:delivery_api/delivery_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'delivery_strings.dart';
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
final class ProofCaptureScreen extends StatefulWidget {
  /// Creates the screen over [controller], for [shipment].
  const ProofCaptureScreen({
    required this.controller,
    required this.shipment,
    this.grade = DeliveryGrade.standard,
    this.onCaptureSignature,
    this.onCapturePhoto,
    this.onSettled,
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

  /// Reports the visit that was recorded, once it is recorded.
  ///
  /// A `DeliveryAttempt` — delivery's own word — and not a destination. What
  /// follows a doorstep is the app's decision: a courier goes on to whatever
  /// is owed on the parcel, and a dispatcher opening the same screen goes
  /// nowhere. §2.4.
  ///
  /// It fires on the transition into [Settled] and once only. A screen that
  /// called this from `build` would call it again on every notification, and
  /// the courier would be sent onward each time the widget rebuilt.
  final void Function(DeliveryAttempt)? onSettled;

  @override
  State<ProofCaptureScreen> createState() => _ProofCaptureScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Static and public so that a test can assert on the key without pumping a
  /// widget tree. Exhaustive over `DeliveryFailure`, which is the point of it
  /// being sealed: the day delivery learns a new way to fail, this stops
  /// compiling instead of quietly showing a courier the wrong sentence.
  @visibleForTesting
  static String describe(DeliveryFailure failure) => switch (failure) {
    OutsideDeliveryArea() => DeliveryStrings.failureOutsideArea,
    DeliveryPositionUnavailable() => DeliveryStrings.failurePositionUnavailable,
    ProofInsufficient() => DeliveryStrings.failureProofInsufficient,
    AttemptAlreadySettled() => DeliveryStrings.failureAlreadySettled,
    ProofStoreUnavailable() => DeliveryStrings.failureProofStoreUnavailable,
    ProofNotFound() => DeliveryStrings.failureProofNotFound,
    MediaTooLarge() => DeliveryStrings.failureMediaTooLarge,
    DeliveryUnavailable() => DeliveryStrings.failureUnavailable,
    MalformedDeliveryValue() => DeliveryStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  ///
  /// The distance is rounded here and not formatted: "12 m" and "12m" are a
  /// locale's question. What is not a locale's question is that a courier does
  /// not need centimetres, and rounding in the app would mean rounding once
  /// per app.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(DeliveryFailure failure) =>
      switch (failure) {
        OutsideDeliveryArea(:final metresAway) => {
          'metres': metresAway.round(),
        },
        ProofInsufficient(:final missing) => {'kinds': missing},
        MalformedDeliveryValue(:final field) => {'field': field},
        DeliveryPositionUnavailable() ||
        AttemptAlreadySettled() ||
        ProofStoreUnavailable() ||
        ProofNotFound() ||
        MediaTooLarge() ||
        DeliveryUnavailable() => const {},
      };
}

class _ProofCaptureScreenState extends State<ProofCaptureScreen> {
  /// Whether the outcome has already been reported.
  ///
  /// Rebuilding is not an event. The controller notifies on every change and
  /// [Settled] stays on screen until somebody leaves it, so without this the
  /// app would be told the visit finished once per notification.
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_announce);
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
  void dispose() {
    widget.controller.removeListener(_announce);
    super.dispose();
  }

  void _announce() {
    final state = widget.controller.state;
    if (_reported || state is! Settled) return;
    _reported = true;
    widget.onSettled?.call(state.attempt);
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(DeliveryStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          AwaitingArrival() || Arriving() => const PeykLoadingView(),
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
          Settled() => PeykEmptyView(
            message: strings.resolve(DeliveryStrings.recorded),
          ),
          CaptureFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              ProofCaptureScreen.describe(failure),
              arguments: ProofCaptureScreen.argumentsFor(failure),
            ),
            onRetry: () => unawaited(
              widget.controller.arrive(
                shipment: widget.shipment,
                grade: widget.grade,
              ),
            ),
          ),
        },
      ),
    );
  }

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
    final strings = PeykStrings.of(context);

    return ListView(
      children: [
        PeykText.body(
          strings.resolve(
            DeliveryStrings.delivering,
            arguments: {'shipment': state.attempt.shipment.value},
          ),
        ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
        // The rule, read from ProofPolicy rather than restated here. A second
        // copy would tell a courier they were finished on the day the policy
        // changed and the use case disagreed.
        if (state.missing.isNotEmpty)
          PeykChip(
            label: strings.resolve(
              DeliveryStrings.stillNeeded,
              arguments: {
                'kinds': [
                  for (final kind in state.missing)
                    strings.resolve(DeliveryStrings.evidenceKind(kind)),
                ],
              },
            ),
            intent: PeykIntent.warning,
          ),
        for (final kind in state.carries)
          PeykChip(
            label: strings.resolve(
              DeliveryStrings.captured,
              arguments: {
                'kind': strings.resolve(DeliveryStrings.evidenceKind(kind)),
              },
            ),
            intent: PeykIntent.success,
          ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
        PeykTextField(
          label: strings.resolve(DeliveryStrings.recipientLabel),
          hint: strings.resolve(DeliveryStrings.recipientHint),
          value: state.recipientName,
          onChanged: onRecipient,
        ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
        if (signature != null)
          PeykButton(
            label: strings.resolve(DeliveryStrings.addSignature),
            onPressed: signature,
          ),
        if (photo != null)
          PeykButton(
            label: strings.resolve(DeliveryStrings.addPhoto),
            onPressed: photo,
          ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions — identity is not one of its
        // collaborators — so this is the last thing between them and a
        // recorded delivery.
        if (canComplete && state.isComplete)
          PeykButton(
            label: strings.resolve(DeliveryStrings.delivered),
            onPressed: onComplete,
            tone: PeykButtonTone.primary,
          ),
        const PeykGap.vertical(PeykGapSize.betweenLines),
        PeykButton(
          label: strings.resolve(DeliveryStrings.couldNotDeliver),
          onPressed: onFail,
          tone: PeykButtonTone.destructive,
        ),
        // An advisory: the refusal happened, and the door is still there to
        // try again from. Replacing the screen would throw away a signature
        // somebody has already collected.
        if (refusal != null) ...[
          const PeykGap.vertical(PeykGapSize.betweenRows),
          PeykChip(
            label: strings.resolve(
              ProofCaptureScreen.describe(refusal),
              arguments: ProofCaptureScreen.argumentsFor(refusal),
            ),
            intent: PeykIntent.danger,
          ),
        ],
      ],
    );
  }
}
