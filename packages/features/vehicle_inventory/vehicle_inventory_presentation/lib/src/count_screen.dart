import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'count_controller.dart';
import 'count_state.dart';
import 'vehicle_inventory_strings.dart';

/// Where a courier counts a van.
///
/// **There is no scanner here.** A presentation package may not depend on
/// `platform/*`, so the barcode arrives as a `ShipmentId` from whatever the
/// app wired to the trigger — the same decision `delivery_presentation` made
/// about the camera in phase 5, for the same reason.
final class CountScreen extends StatelessWidget {
  /// Creates the screen over [controller].
  const CountScreen({required this.controller, super.key});

  /// What drives it.
  final CountController controller;

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `VehicleInventoryFailure`.
  @visibleForTesting
  static String describe(VehicleInventoryFailure failure) => switch (failure) {
    ManifestUnavailable() => VehicleInventoryStrings.failureManifestUnavailable,
    CountUnavailable() => VehicleInventoryStrings.failureCountUnavailable,
    CountMissing() => VehicleInventoryStrings.failureCountMissing,
    CountClosed() => VehicleInventoryStrings.failureCountClosed,
    MalformedCount() => VehicleInventoryStrings.failureMalformed,
  };

  /// Whether asking again is the answer to [failure].
  ///
  /// A closed count is not reopened by retrying, and a count that is gone
  /// stays gone. Both need a new count, which is a different button on a
  /// different screen.
  @visibleForTesting
  static bool canRetry(VehicleInventoryFailure failure) => switch (failure) {
    CountClosed() || CountMissing() => false,
    ManifestUnavailable() || CountUnavailable() || MalformedCount() => true,
  };

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(VehicleInventoryStrings.title),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => switch (controller.state) {
          CountIdle() => PeykEmptyView(
            message: strings.resolve(VehicleInventoryStrings.idle),
          ),
          CountPreparing() => const PeykLoadingView(),
          CountInProgress(:final count) => _Progress(
            count: count,
            closed: false,
          ),
          CountClosedState(:final count) => _Progress(
            count: count,
            closed: true,
          ),
          CountFailed(:final failure) => PeykFailureView(
            message: strings.resolve(CountScreen.describe(failure)),
            // resume() rather than a retry of its own: what failed was
            // reading whether a count is open, and asking again is exactly
            // that question.
            onRetry: CountScreen.canRetry(failure)
                ? () => unawaited(controller.resume())
                : null,
          ),
        },
      ),
    );
  }
}

/// The two numbers a courier reads, and the third one they argue about.
///
/// Scanned over expected, then what is missing and what should not be there.
/// The numbers come off `LoadCount` — this widget does no arithmetic, because
/// the arithmetic is the feature. Phase 6 wrote that down as a rule: a count is
/// derived, never stored, so a widget that added anything up would be a second
/// place the total could be wrong.
///
/// Missing is danger and unexpected is warning, and they are not the same
/// thing. A parcel the van does not have is a delivery that will not happen;
/// a parcel nobody expected is paperwork.
class _Progress extends StatelessWidget {
  const _Progress({required this.count, required this.closed});

  final LoadCount count;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PeykText.display(
          strings.resolve(
            VehicleInventoryStrings.progress,
            arguments: {
              'scanned': count.scanned.length,
              'expected': count.manifest.length,
            },
          ),
        ),
        if (count.missing.isNotEmpty) ...[
          const PeykGap.vertical(PeykGapSize.betweenRows),
          PeykChip(
            label: strings.resolve(
              VehicleInventoryStrings.missing,
              arguments: {'count': count.missing.length},
            ),
            intent: PeykIntent.danger,
          ),
        ],
        if (count.unexpected.isNotEmpty) ...[
          const PeykGap.vertical(PeykGapSize.betweenLines),
          PeykChip(
            label: strings.resolve(
              VehicleInventoryStrings.unexpected,
              arguments: {'count': count.unexpected.length},
            ),
            intent: PeykIntent.warning,
          ),
        ],
        if (closed && count.isReconciled) ...[
          const PeykGap.vertical(PeykGapSize.betweenRows),
          PeykChip(
            label: strings.resolve(VehicleInventoryStrings.reconciled),
            intent: PeykIntent.success,
          ),
        ],
      ],
    );
  }
}
