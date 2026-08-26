import 'package:flutter/widgets.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'count_controller.dart';
import 'count_state.dart';

/// Where a courier counts a van.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system` in phase 7.
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

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `VehicleInventoryFailure`.
  static String describe(VehicleInventoryFailure failure) => switch (failure) {
    ManifestUnavailable() => 'The load list could not be reached.',
    CountUnavailable() => 'This count could not be saved.',
    CountMissing() => 'That count is no longer open.',
    CountClosed() => 'This count is already finished.',
    MalformedCount() => 'The load list could not be read.',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => switch (controller.state) {
      CountIdle() => const Text('inventory.idle'),
      CountPreparing() => const Text('inventory.preparing'),
      CountInProgress(:final count) => _Progress(count: count, closed: false),
      CountClosedState(:final count) => _Progress(count: count, closed: true),
      CountFailed(:final failure) => Text(CountScreen.describe(failure)),
    },
  );
}

/// The two numbers a courier reads, and the third one they argue about.
///
/// Scanned over expected, then what is missing and what should not be there.
/// The numbers come off `LoadCount` — this widget does no arithmetic, because
/// the arithmetic is the feature.
class _Progress extends StatelessWidget {
  const _Progress({required this.count, required this.closed});

  final LoadCount count;
  final bool closed;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('${count.scanned.length}/${count.manifest.length}'),
      if (count.missing.isNotEmpty)
        Text('inventory.missing ${count.missing.length}'),
      if (count.unexpected.isNotEmpty)
        Text('inventory.unexpected ${count.unexpected.length}'),
      if (closed && count.isReconciled) const Text('inventory.reconciled'),
    ],
  );
}
