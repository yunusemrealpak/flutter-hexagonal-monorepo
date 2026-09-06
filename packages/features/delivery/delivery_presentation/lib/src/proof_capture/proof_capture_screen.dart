import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipments_api/shipments_api.dart';

import '../delivery_strings.dart';
import 'proof_capture_bloc.dart';
import 'proof_capture_event.dart';
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
/// **This is the screen that pays for `BlocSelector`.** A keystroke in the
/// recipient field emits a new `AtTheDoor` several times a second, and the
/// chips, the buttons and the parcel line above them are identical in every
/// one of those states. `buildWhen` on the case narrows the outer switch to
/// the four transitions that change *what kind of thing* is on screen, and
/// each part of the door then subscribes to the one value it draws.
///
/// **What a selector selects is what reaches the pixels, not the state it came
/// from.** `BlocSelector` rebuilds on `!=`, and the states here hold entities
/// and have no `==` — selecting `AtTheDoor.notice` would compare two objects
/// by identity and rebuild whenever a copy was made. Selecting the resolved
/// label, a `bool` or a record of them compares exactly the thing a difference
/// in would be visible, so the rebuild happens when the picture changes and
/// not when the state does.
final class ProofCaptureScreen extends StatefulWidget {
  /// Creates the screen for [shipment].
  const ProofCaptureScreen({
    required this.shipment,
    this.grade = DeliveryGrade.standard,
    this.onCaptureSignature,
    this.onCapturePhoto,
    this.onSettled,
    this.onOpenSettings,
    super.key,
  });

  /// Which parcel this visit is about.
  final ShipmentId shipment;

  /// How much proof it is worth.
  ///
  /// Supplied by whoever already had the manifest row in hand. Delivery never
  /// reads a `Shipment` to work this out — section 2.1 — and this parameter is
  /// where the translation between the two features' vocabularies happens.
  final DeliveryGrade grade;

  /// Opens whatever this app captures signatures with.
  final Future<Result<SignatureCapture, CaptureRefusal>> Function()?
  onCaptureSignature;

  /// Opens whatever this app takes photographs with.
  ///
  /// A `Result` rather than a nullable evidence, and the widening is what the
  /// whole blocked path turns on: answering `null` made a camera switched off
  /// in the system settings identical to a courier who changed their mind, so
  /// the one outcome with a way out of it was the one nothing offered a way
  /// out of. `CaptureRefusal` has a case per thing a courier does next.
  final Future<Result<PhotoEvidence, CaptureRefusal>> Function()?
  onCapturePhoto;

  /// Opens this device's settings page for the application.
  ///
  /// The other half of every blocked permission on this screen, and a callback
  /// for the same reason the captures are: opening it means
  /// `PermissionRequester`, which lives in `core_ports` — a package section 2
  /// does not give a presentation package. A decision the product owns is a
  /// port; a mechanism the platform owns is a callback, and `AlertsBloc` took
  /// the same argument for the same reason.
  ///
  /// An app that supplies none draws no button, which is what
  /// `app_dispatcher` relies on: a desk has no camera permission to unblock.
  final Future<bool> Function()? onOpenSettings;

  /// Reports the visit that was recorded, once it is recorded.
  ///
  /// A `DeliveryAttempt` — delivery's own word — and not a destination. What
  /// follows a doorstep is the app's decision: a courier goes on to whatever
  /// is owed on the parcel, and a dispatcher opening the same screen goes
  /// nowhere. §2.4.
  ///
  /// It fires on the transition into [Settled] and once only. That used to
  /// need a `bool` on the state class, because a `ChangeNotifier` announces a
  /// value and cannot say what changed; `BlocConsumer.listenWhen` sees both
  /// states and the flag is gone.
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
    DevicePositionBlocked() => DeliveryStrings.failurePositionBlocked,
    ProofInsufficient() => DeliveryStrings.failureProofInsufficient,
    AttemptAlreadySettled() => DeliveryStrings.failureAlreadySettled,
    ProofStoreUnavailable() => DeliveryStrings.failureProofStoreUnavailable,
    ProofNotFound() => DeliveryStrings.failureProofNotFound,
    MediaTooLarge() => DeliveryStrings.failureMediaTooLarge,
    DeliveryUnavailable() => DeliveryStrings.failureUnavailable,
    MalformedDeliveryValue() => DeliveryStrings.failureMalformed,
  };

  /// Which string a capture refusal should be shown as, or null for one that
  /// is shown as nothing.
  ///
  /// [CaptureDeclined] is the null. A courier who opened the camera and backed
  /// out is behaving normally, and a red chip in front of them would be the
  /// screen reporting an event rather than a problem.
  @visibleForTesting
  static String? describeCapture(CaptureRefusal refusal) => switch (refusal) {
    CaptureDeclined() => null,
    CaptureNotAllowed() => DeliveryStrings.captureNotAllowed,
    CaptureBlockedInSettings() => DeliveryStrings.captureBlocked,
    EvidenceUnusable(:final failure) => describe(failure),
  };

  /// The arguments [refusal] contributes to its own message.
  @visibleForTesting
  static Map<String, Object?> argumentsForCapture(CaptureRefusal refusal) =>
      switch (refusal) {
        EvidenceUnusable(:final failure) => argumentsFor(failure),
        CaptureDeclined() ||
        CaptureNotAllowed() ||
        CaptureBlockedInSettings() => const {},
      };

  /// Whether the way out of [refusal] is the settings page.
  ///
  /// Exactly one of the four. Offering it for [CaptureNotAllowed] would send
  /// somebody the long way round to a prompt the button in front of them
  /// already shows.
  @visibleForTesting
  static bool captureNeedsSettings(CaptureRefusal refusal) =>
      refusal is CaptureBlockedInSettings;

  /// Whether the way out of [failure] is the settings page rather than a
  /// retry.
  ///
  /// Static and public for the reason [describe] is: an app drawing the same
  /// failure in a different shape should not have to rediscover which of them
  /// a retry cannot help.
  @visibleForTesting
  static bool needsSettings(DeliveryFailure failure) => switch (failure) {
    DevicePositionBlocked() => true,
    OutsideDeliveryArea() ||
    DeliveryPositionUnavailable() ||
    ProofInsufficient() ||
    AttemptAlreadySettled() ||
    ProofStoreUnavailable() ||
    ProofNotFound() ||
    MediaTooLarge() ||
    DeliveryUnavailable() ||
    MalformedDeliveryValue() => false,
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
        DevicePositionBlocked() ||
        AttemptAlreadySettled() ||
        ProofStoreUnavailable() ||
        ProofNotFound() ||
        MediaTooLarge() ||
        DeliveryUnavailable() => const {},
      };
}

class _ProofCaptureScreenState extends State<ProofCaptureScreen> {
  @override
  void initState() {
    super.initState();
    // The arrival is genuinely fire-and-forget: its result reaches the screen
    // as a state, not as a returned value, which is what lets `initState`
    // start a network round trip without being async.
    context.read<ProofCaptureBloc>().add(
      ArrivalRequested(shipment: widget.shipment, grade: widget.grade),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(DeliveryStrings.title),
      body: BlocConsumer<ProofCaptureBloc, ProofCaptureState>(
        // Rebuilding is not an event, and this is the pair of states that says
        // so. [Settled] stays on screen until somebody leaves it, so a screen
        // that announced from `build` would send the courier onward once per
        // frame.
        listenWhen: (previous, current) =>
            previous is! Settled && current is Settled,
        listener: (context, state) =>
            widget.onSettled?.call((state as Settled).attempt),
        // Only the four transitions that change what kind of thing is on
        // screen. `AtTheDoor` following itself is the common case — a
        // keystroke, an evidence chip, a refusal — and the door redraws those
        // parts through the selectors inside it rather than by rebuilding.
        //
        // Safe on `runtimeType` because no case here can follow itself in a
        // way a rebuild would show: a retry emits [Arriving] before it can
        // reach [CaptureFailed] again, and [Settled] is terminal.
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) => switch (state) {
          AwaitingArrival() || Arriving() => const PeykLoadingView(),
          AtTheDoor() => _Door(
            onOpenSettings: widget.onOpenSettings == null
                ? null
                : () => unawaited(widget.onOpenSettings!()),
            onSignature: widget.onCaptureSignature == null
                ? null
                : () => unawaited(_capture(_Kind.signature)),
            onPhoto: widget.onCapturePhoto == null
                ? null
                : () => unawaited(_capture(_Kind.photo)),
          ),
          Settled() => PeykEmptyView(
            message: strings.resolve(DeliveryStrings.recorded),
          ),
          CaptureFailed(:final failure) => _failure(context, failure),
        },
      ),
    );
  }

  /// The failure view, with whichever way out this failure has.
  ///
  /// A blocked permission gets the settings page and *no retry*: the operating
  /// system has stopped asking, so trying again shows nothing at all. Drawing
  /// both would put the useless button first.
  Widget _failure(BuildContext context, DeliveryFailure failure) {
    final strings = PeykStrings.of(context);
    final settings = widget.onOpenSettings;
    final blocked = ProofCaptureScreen.needsSettings(failure);

    return PeykFailureView(
      message: strings.resolve(
        ProofCaptureScreen.describe(failure),
        arguments: ProofCaptureScreen.argumentsFor(failure),
      ),
      onRetry: blocked
          ? null
          : () => context.read<ProofCaptureBloc>().add(
              ArrivalRequested(shipment: widget.shipment, grade: widget.grade),
            ),
      actionLabel: blocked && settings != null
          ? strings.resolve(DeliveryStrings.openSettings)
          : null,
      onAction: blocked && settings != null
          ? () => unawaited(settings())
          : null,
    );
  }

  Future<void> _capture(_Kind kind) async {
    switch (kind) {
      case _Kind.signature:
        final capture = await widget.onCaptureSignature!();
        if (!mounted) return;
        context.read<ProofCaptureBloc>().add(SignatureCaptured(capture));
      case _Kind.photo:
        final capture = await widget.onCapturePhoto!();
        if (!mounted) return;
        context.read<ProofCaptureBloc>().add(PhotoCaptured(capture));
    }
  }
}

enum _Kind { signature, photo }

/// The door itself: one subscription per thing that can change on it.
///
/// Nothing here is passed the state. Every part reads the one value it draws
/// through a `BlocSelector`, which is what makes the `buildWhen` above safe —
/// the outer switch stops rebuilding while `AtTheDoor` follows itself, and the
/// parts that actually changed still redraw.
final class _Door extends StatelessWidget {
  const _Door({this.onSignature, this.onPhoto, this.onOpenSettings});

  final VoidCallback? onSignature;
  final VoidCallback? onPhoto;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final signature = onSignature;
    final photo = onPhoto;
    final settings = onOpenSettings;
    final bloc = context.read<ProofCaptureBloc>();
    final strings = PeykStrings.of(context);

    return ListView(
      children: [
        // Which parcel. The same sentence for the whole visit, and a keystroke
        // in the name field below must not redraw it.
        BlocSelector<ProofCaptureBloc, ProofCaptureState, String>(
          selector: (state) =>
              state is AtTheDoor ? state.attempt.shipment.value : '',
          builder: (context, shipment) => PeykText.body(
            strings.resolve(
              DeliveryStrings.delivering,
              arguments: {'shipment': shipment},
            ),
          ),
        ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
        // The rule, read from ProofPolicy rather than restated here. A second
        // copy would tell a courier they were finished on the day the policy
        // changed and the use case disagreed.
        //
        // The selected value is the resolved sentence, so this rebuilds when
        // the sentence changes and not when the set behind it is rebuilt into
        // an equal one.
        BlocSelector<ProofCaptureBloc, ProofCaptureState, String?>(
          selector: (state) => switch (state) {
            AtTheDoor(:final missing) when missing.isNotEmpty =>
              strings.resolve(
                DeliveryStrings.stillNeeded,
                arguments: {
                  'kinds': [
                    for (final kind in missing)
                      strings.resolve(DeliveryStrings.evidenceKind(kind)),
                  ],
                },
              ),
            _ => null,
          },
          builder: (context, label) => label == null
              ? const SizedBox.shrink()
              : PeykChip(label: label, intent: PeykIntent.warning),
        ),
        // One subscription per kind rather than one over the set: a `Set` has
        // no value equality, so a selector over `carries` would rebuild on
        // every emission and buy nothing.
        for (final kind in EvidenceKind.values)
          BlocSelector<ProofCaptureBloc, ProofCaptureState, bool>(
            selector: (state) =>
                state is AtTheDoor && state.carries.contains(kind),
            builder: (context, carried) => carried
                ? PeykChip(
                    label: strings.resolve(
                      DeliveryStrings.captured,
                      arguments: {
                        'kind': strings.resolve(
                          DeliveryStrings.evidenceKind(kind),
                        ),
                      },
                    ),
                    intent: PeykIntent.success,
                  )
                : const SizedBox.shrink(),
          ),
        const PeykGap.vertical(PeykGapSize.betweenRows),
        BlocSelector<ProofCaptureBloc, ProofCaptureState, String>(
          selector: (state) => state is AtTheDoor ? state.recipientName : '',
          builder: (context, name) => PeykTextField(
            label: strings.resolve(DeliveryStrings.recipientLabel),
            hint: strings.resolve(DeliveryStrings.recipientHint),
            value: name,
            onChanged: (value) => bloc.add(RecipientNamed(value)),
          ),
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
        // What the last capture came back with, and — for the one case only
        // the system settings can change — the way out of it. Beside the
        // buttons rather than replacing the screen: a camera that would not
        // open has not invalidated a signature already on the glass.
        BlocSelector<ProofCaptureBloc, ProofCaptureState, (String?, bool)>(
          selector: (state) => switch (state) {
            AtTheDoor(notice: final notice?) => (
              _resolveCapture(strings, notice),
              ProofCaptureScreen.captureNeedsSettings(notice),
            ),
            _ => (null, false),
          },
          builder: (context, notice) {
            final (label, needsSettings) = notice;
            if (label == null) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PeykGap.vertical(PeykGapSize.betweenLines),
                PeykChip(label: label, intent: PeykIntent.warning),
                if (settings != null && needsSettings) ...[
                  const PeykGap.vertical(PeykGapSize.betweenLines),
                  PeykButton(
                    label: strings.resolve(DeliveryStrings.openSettings),
                    onPressed: settings,
                  ),
                ],
              ],
            );
          },
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        // Scenario 6: the action a courier without the grant never sees. The
        // use case does not check permissions — identity is not one of its
        // collaborators — so this is the last thing between them and a
        // recorded delivery.
        //
        // `canComplete` is read inside the selector, which runs on every
        // emission. That is deliberate: the answer lives on the bloc rather
        // than in the state precisely so that a grant revoked mid-shift is
        // seen, and a selector reading it keeps that while still rebuilding
        // only when the pair changes.
        BlocSelector<ProofCaptureBloc, ProofCaptureState, (bool, bool)>(
          selector: (state) => (
            bloc.canComplete,
            state is AtTheDoor && state.isComplete,
          ),
          builder: (context, offer) {
            final (canComplete, isComplete) = offer;
            if (!canComplete || !isComplete) return const SizedBox.shrink();

            return PeykButton(
              label: strings.resolve(DeliveryStrings.delivered),
              onPressed: () => bloc.add(const HandoverRecorded()),
              tone: PeykButtonTone.primary,
            );
          },
        ),
        const PeykGap.vertical(PeykGapSize.betweenLines),
        PeykButton(
          label: strings.resolve(DeliveryStrings.couldNotDeliver),
          onPressed: () => bloc.add(
            const NonDeliveryRecorded(NonDeliveryReason.recipientAbsent()),
          ),
          tone: PeykButtonTone.destructive,
        ),
        // An advisory: the refusal happened, and the door is still there to
        // try again from. Replacing the screen would throw away a signature
        // somebody has already collected.
        BlocSelector<ProofCaptureBloc, ProofCaptureState, String?>(
          selector: (state) => switch (state) {
            AtTheDoor(refusal: final refusal?) => strings.resolve(
              ProofCaptureScreen.describe(refusal),
              arguments: ProofCaptureScreen.argumentsFor(refusal),
            ),
            _ => null,
          },
          builder: (context, label) => label == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PeykGap.vertical(PeykGapSize.betweenRows),
                    PeykChip(label: label, intent: PeykIntent.danger),
                  ],
                ),
        ),
      ],
    );
  }

  /// The sentence a refusal is drawn as, or null for the one drawn as nothing.
  static String? _resolveCapture(
    StringCatalogue strings,
    CaptureRefusal refusal,
  ) {
    final key = ProofCaptureScreen.describeCapture(refusal);
    return key == null
        ? null
        : strings.resolve(
            key,
            arguments: ProofCaptureScreen.argumentsForCapture(refusal),
          );
  }
}
