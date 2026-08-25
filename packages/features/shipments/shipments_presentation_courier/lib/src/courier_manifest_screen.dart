import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'courier_manifest_controller.dart';
import 'courier_manifest_state.dart';

/// The courier's stop list.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7, and inventing them here
/// would mean deleting them then. What this widget demonstrates now is the
/// part that will not change — a screen renders a sealed state exhaustively
/// and reaches nothing but ports.
///
/// It takes the controller rather than building one. A widget that constructed
/// its own would have to know which adapters are behind it, and that decision
/// belongs to an app.
final class CourierManifestScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const CourierManifestScreen({required this.controller, super.key});

  /// What drives it.
  final CourierManifestController controller;

  @override
  State<CourierManifestScreen> createState() => _CourierManifestScreenState();
}

class _CourierManifestScreenState extends State<CourierManifestScreen> {
  @override
  void initState() {
    super.initState();
    // initState cannot be async, and the load is genuinely
    // fire-and-forget: its result reaches the screen through the
    // controller's notification rather than through this call.
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      ManifestIdle() || ManifestLoading() => const Center(
        child: Text('Loading your stops'),
      ),
      ManifestReady(:final rows) when rows.isEmpty => const Center(
        // Not an error. "Nothing assigned to you yet" is an ordinary
        // morning, and an error here would have couriers calling the
        // depot before their first parcel.
        child: Text('Nothing assigned yet'),
      ),
      ManifestReady(:final rows) => ListView(
        children: [for (final row in rows) _StopTile(row: row)],
      ),
      ManifestFailed(:final failure) => Center(
        child: Text(_describe(failure)),
      ),
    },
  );

  /// Turns a failure into something a courier can act on.
  ///
  /// The translation happens here rather than in the state, because this is
  /// where the locale is known. A state object carrying a formatted English
  /// string would be untranslatable a phase later.
  static String _describe(ShipmentFailure failure) => switch (failure) {
    ShipmentsUnavailable() => 'No signal. Showing what is on this device.',
    ShipmentNotFound() => 'That shipment is no longer in the operation.',
    _ => 'Something went wrong. Try again.',
  };
}

final class _StopTile extends StatelessWidget {
  const _StopTile({required this.row});

  final ShipmentSummary row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(row.consigneeName),
        Text(row.address),
        Text(row.status.label),
      ],
    ),
  );
}
