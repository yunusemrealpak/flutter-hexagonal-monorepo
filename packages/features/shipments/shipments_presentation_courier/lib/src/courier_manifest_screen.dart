import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'courier_manifest_controller.dart';
import 'courier_manifest_state.dart';
import 'shipments_courier_strings.dart';

/// The courier's stop list.
///
/// It takes the controller rather than building one. A widget that constructed
/// its own would have to know which adapters are behind it, and that decision
/// belongs to an app.
///
/// **The same feature, drawn twice.** `shipments_presentation_dispatcher`
/// renders the same `ShipmentSummary` rows as a selectable board. Scenario 7
/// is that neither package knows the other exists: both depend on
/// `shipments_api` and on nothing else of shipments'.
final class CourierManifestScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const CourierManifestScreen({required this.controller, super.key});

  /// What drives it.
  final CourierManifestController controller;

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
    // initState cannot be async, and the load is genuinely fire-and-forget:
    // its result reaches the screen through the controller's notification
    // rather than through this call.
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(ShipmentsCourierStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          ManifestIdle() || ManifestLoading() => const PeykLoadingView(),
          // Not an error. "Nothing assigned to you yet" is an ordinary
          // morning, and a failure view here would have couriers calling the
          // depot before their first parcel.
          ManifestReady(:final rows) when rows.isEmpty => PeykEmptyView(
            message: strings.resolve(ShipmentsCourierStrings.empty),
          ),
          ManifestReady(:final rows) => ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) => _StopTile(row: rows[index]),
          ),
          ManifestFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              CourierManifestScreen.describe(failure),
            ),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
}

final class _StopTile extends StatelessWidget {
  const _StopTile({required this.row});

  final ShipmentSummary row;

  @override
  Widget build(BuildContext context) => PeykListRow(
    title: row.consigneeName,
    subtitle: row.address,
    trailing: PeykChip(
      label: PeykStrings.of(
        context,
      ).resolve(ShipmentsCourierStrings.status(row.status)),
      intent: CourierManifestScreen.intentOf(row.status),
    ),
  );
}
