import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import '../vehicle_inventory_strings.dart';
import 'count_bloc.dart';
import 'count_event.dart';
import 'count_state.dart';

/// Where a courier counts a van.
///
/// **There is no scanner here.** A presentation package may not depend on
/// `platform/*`, so the barcode arrives as a `ShipmentId` from whatever the
/// app wired to the trigger — the same decision `delivery_presentation` made
/// about the camera in phase 5, for the same reason.
/// The bloc arrives through the widget tree: whoever mounts this screen puts a
/// [CountBloc] above it with `BlocProvider`.
final class CountScreen extends StatelessWidget {
  /// Creates the screen.
  const CountScreen({super.key});

  /// The count on screen, or `null` while there is not one.
  ///
  /// Every selector below goes through this. A `BlocSelector` runs against
  /// whatever the state is *now*, which can be a case the outer builder has
  /// not drawn yet — an emission can land between the two rebuilds — so a
  /// selector that assumed its case would throw on the frame in between.
  static LoadCount? _countOf(CountState state) => switch (state) {
    CountInProgress(:final count) || CountClosedState(:final count) => count,
    CountIdle() || CountPreparing() || CountFailed() => null,
  };

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
      // **`buildWhen` is what makes the selectors in `_Progress` worth
      // writing**, and this is the package that needs them most: a scanner
      // fires several times a second, and without narrowing here every scan
      // would rebuild the whole subtree and re-create the selectors rather
      // than skip them.
      //
      // It is safe because no case this bloc emits can follow itself. Reading
      // and starting both emit `CountPreparing` first, a scan only fires from
      // `CountInProgress`, and a failure ends the sequence.
      body: BlocBuilder<CountBloc, CountState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) => switch (state) {
          CountIdle() => PeykEmptyView(
            message: strings.resolve(VehicleInventoryStrings.idle),
          ),
          CountPreparing() => const PeykLoadingView(),
          CountInProgress() => const _Progress(closed: false),
          CountClosedState() => const _Progress(closed: true),
          CountFailed(:final failure) => PeykFailureView(
            message: strings.resolve(CountScreen.describe(failure)),
            // resume() rather than a retry of its own: what failed was
            // reading whether a count is open, and asking again is exactly
            // that question.
            onRetry: CountScreen.canRetry(failure)
                ? () => context.read<CountBloc>().add(const CountResumed())
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
  const _Progress({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A record, so the two numbers travel as one value with the value
        // equality a record has. Two selectors would rebuild this line twice
        // for a scan that changed both.
        BlocSelector<CountBloc, CountState, (int, int)?>(
          selector: (state) {
            final count = CountScreen._countOf(state);
            return count == null
                ? null
                : (count.scanned.length, count.manifest.length);
          },
          builder: (context, progress) => progress == null
              ? const PeykGap.vertical(PeykGapSize.betweenRows)
              : PeykText.display(
                  strings.resolve(
                    VehicleInventoryStrings.progress,
                    arguments: {
                      'scanned': progress.$1,
                      'expected': progress.$2,
                    },
                  ),
                ),
        ),
        // Scanning a parcel that is on the manifest moves this number and
        // leaves the one below it alone — which is the whole reason the two
        // chips select separately rather than sharing a builder.
        BlocSelector<CountBloc, CountState, int>(
          selector: (state) => CountScreen._countOf(state)?.missing.length ?? 0,
          builder: (context, missing) => missing == 0
              ? const PeykGap.vertical(PeykGapSize.betweenRows)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PeykGap.vertical(PeykGapSize.betweenRows),
                    PeykChip(
                      label: strings.resolve(
                        VehicleInventoryStrings.missing,
                        arguments: {'count': missing},
                      ),
                      intent: PeykIntent.danger,
                    ),
                  ],
                ),
        ),
        BlocSelector<CountBloc, CountState, int>(
          selector: (state) =>
              CountScreen._countOf(state)?.unexpected.length ?? 0,
          builder: (context, unexpected) => unexpected == 0
              ? const PeykGap.vertical(PeykGapSize.betweenLines)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PeykGap.vertical(PeykGapSize.betweenLines),
                    PeykChip(
                      label: strings.resolve(
                        VehicleInventoryStrings.unexpected,
                        arguments: {'count': unexpected},
                      ),
                      intent: PeykIntent.warning,
                    ),
                  ],
                ),
        ),
        if (closed)
          BlocSelector<CountBloc, CountState, bool>(
            selector: (state) =>
                CountScreen._countOf(state)?.isReconciled ?? false,
            builder: (context, reconciled) => reconciled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PeykGap.vertical(PeykGapSize.betweenRows),
                      PeykChip(
                        label: strings.resolve(
                          VehicleInventoryStrings.reconciled,
                        ),
                        intent: PeykIntent.success,
                      ),
                    ],
                  )
                : const PeykGap.vertical(PeykGapSize.betweenRows),
          ),
      ],
    );
  }
}
