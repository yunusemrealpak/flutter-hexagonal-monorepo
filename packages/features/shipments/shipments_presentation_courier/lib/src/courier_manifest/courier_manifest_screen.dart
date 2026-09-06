import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipments_api/shipments_api.dart';

import '../shipments_courier_strings.dart';
import 'courier_manifest_bloc.dart';
import 'courier_manifest_event.dart';
import 'courier_manifest_state.dart';

/// The courier's stop list.
///
/// It reads its bloc from the tree rather than building one. A widget that
/// constructed its own would have to know which adapters are behind it, and
/// that decision belongs to an app.
///
/// **The same feature, drawn twice.** `shipments_presentation_dispatcher`
/// renders the same `ShipmentSummary` rows as a selectable board. Scenario 7
/// is that neither package knows the other exists: both depend on
/// `shipments_api` and on nothing else of shipments'.
///
/// **`buildWhen` compares the rows by identity.** Fetching the next page emits
/// twice — once to raise `loadingMore`, once with the longer list — and only
/// the second changes a stop tile. The list is immutable, so a different
/// object is a different list; the tail row, which is what the first emission
/// is *for*, selects the two fields it draws.
final class CourierManifestScreen extends StatefulWidget {
  /// Creates the screen. Its bloc comes from the tree above it.
  const CourierManifestScreen({this.onStopSelected, super.key});

  /// Reports the stop somebody chose, when this app has somewhere to take it.
  ///
  /// A `ShipmentSummary` — this feature's own word — and not a route. Where a
  /// courier goes from a stop is the app's decision, and §2.4 keeps it there:
  /// `shipments` may not import `delivery_presentation`, so it could not name
  /// that destination even if it wanted to. An app that only lists stops
  /// passes nothing and the rows do not respond.
  final void Function(ShipmentSummary)? onStopSelected;

  @override
  State<CourierManifestScreen> createState() => _CourierManifestScreenState();

  /// Which string a failure should be shown as.
  ///
  /// `ShipmentFailure` carries cases only an adapter produces, so the wildcard
  /// is real rather than lazy. The two named cases are the two a courier
  /// standing next to a van can do something about.
  @visibleForTesting
  static String describe(ShipmentFailure failure) => switch (failure) {
    ShipmentsUnavailable() => ShipmentsCourierStrings.failureUnavailable,
    ShipmentNotFound() => ShipmentsCourierStrings.failureNotFound,
    _ => ShipmentsCourierStrings.failureOther,
  };

  /// How a status should be drawn on a courier's list.
  ///
  /// The mapping is shipments' and not the design system's: a component knows
  /// what `success` looks like, and only shipments knows that a parcel in a
  /// consignee's hands is one.
  ///
  /// `undeliverable` is a warning rather than a danger here, and that is the
  /// courier's point of view — the visit is over and the parcel is coming back
  /// to the depot, which is a normal outcome of a delivery round. The
  /// dispatcher's board draws the same status as danger, because on that
  /// screen it is a parcel somebody has to do something about.
  @visibleForTesting
  static PeykIntent intentOf(ShipmentStatus status) => switch (status) {
    ShipmentDeliveredToConsignee() => PeykIntent.success,
    ShipmentOutForDelivery() => PeykIntent.info,
    ShipmentUndeliverable() || ShipmentReturnedToDepot() => PeykIntent.warning,
    ShipmentAwaitingAssignment() ||
    ShipmentAssignedToCourier() ||
    ShipmentLoadedOnVehicle() => PeykIntent.neutral,
  };
}

class _CourierManifestScreenState extends State<CourierManifestScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the answer arrives as a state rather than as a
    // returned value, which is what lets `initState` start a network round
    // trip without being async.
    context.read<CourierManifestBloc>().add(const ManifestRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(ShipmentsCourierStrings.title),
      body: BlocBuilder<CourierManifestBloc, CourierManifestState>(
        // A longer list redraws the list; raising `loadingMore` does not,
        // because the tail row selects that for itself.
        buildWhen: (previous, current) => switch ((previous, current)) {
          (ManifestReady(rows: final before), ManifestReady(rows: final after))
              when identical(before, after) =>
            false,
          _ => true,
        },
        builder: (context, state) => switch (state) {
          ManifestIdle() || ManifestLoading() => const PeykLoadingView(),
          // Not an error. "Nothing assigned to you yet" is an ordinary
          // morning, and a failure view here would have couriers calling the
          // depot before their first parcel.
          ManifestReady(:final rows, hasMore: false) when rows.isEmpty =>
            PeykEmptyView(
              message: strings.resolve(ShipmentsCourierStrings.empty),
            ),
          final ManifestReady state => ListView.builder(
            // One extra row when there is more, and it is the affordance
            // rather than an automatic fetch. Asking for the next page from
            // `itemBuilder` would start a request during a build, and a list
            // that does that fires several in one scroll gesture. An app that
            // wants a round to load as it is scrolled drives `loadMore` from a
            // scroll listener it owns; the controller's in-flight guard is
            // what makes that safe either way.
            itemCount: state.rows.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) => index == state.rows.length
                ? const _More()
                : _StopTile(
                    row: state.rows[index],
                    onSelected: widget.onStopSelected,
                  ),
          ),
          ManifestFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              CourierManifestScreen.describe(failure),
            ),
            onRetry: () => context.read<CourierManifestBloc>().add(
              const ManifestRequested(),
            ),
          ),
        },
      ),
    );
  }
}

/// The tail of the list: fetch the next page, or say why the last try did not.
///
/// It is one widget rather than three states drawn by the parent because all
/// three occupy the same slot, and a courier who has just failed to load more
/// still needs the way to try again in the place they were looking.
///
/// The two things it draws are selected rather than passed, which is what lets
/// the list above ignore the emission that only raised `loadingMore`. A
/// `(bool, String?)` record has value equality all the way down, so this
/// rebuilds when the tail changes and not when the state does.
final class _More extends StatelessWidget {
  const _More();

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return BlocSelector<
      CourierManifestBloc,
      CourierManifestState,
      (bool, String?)
    >(
      selector: (state) => switch (state) {
        ManifestReady(:final loadingMore, :final moreFailure) => (
          loadingMore,
          moreFailure == null
              ? null
              : strings.resolve(CourierManifestScreen.describe(moreFailure)),
        ),
        _ => (false, null),
      },
      builder: (context, tail) {
        final (loadingMore, failure) = tail;
        if (loadingMore) return const PeykLoadingView();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (failure != null) ...[
              PeykChip(
                label: strings.resolve(ShipmentsCourierStrings.moreFailed),
                intent: PeykIntent.warning,
              ),
              const PeykGap.vertical(PeykGapSize.betweenLines),
              // The failure is named for the log-reading reader of this file:
              // the chip says the page did not arrive, and `describe` is what
              // an app would use to say why in a banner it owns.
              PeykText.caption(failure),
              const PeykGap.vertical(PeykGapSize.betweenLines),
            ],
            PeykButton(
              label: strings.resolve(ShipmentsCourierStrings.loadMore),
              onPressed: () => context.read<CourierManifestBloc>().add(
                const MoreRequested(),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _StopTile extends StatelessWidget {
  const _StopTile({required this.row, this.onSelected});

  final ShipmentSummary row;
  final void Function(ShipmentSummary)? onSelected;

  @override
  Widget build(BuildContext context) => PeykListRow(
    title: row.consigneeName,
    subtitle: row.address,
    onTap: onSelected == null ? null : () => onSelected!(row),
    trailing: PeykChip(
      label: PeykStrings.of(
        context,
      ).resolve(ShipmentsCourierStrings.status(row.status)),
      intent: CourierManifestScreen.intentOf(row.status),
    ),
  );
}
