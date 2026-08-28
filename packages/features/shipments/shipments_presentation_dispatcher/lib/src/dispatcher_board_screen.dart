import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'dispatcher_board_controller.dart';
import 'dispatcher_board_state.dart';
import 'shipments_dispatcher_strings.dart';

/// The dispatcher's board: every shipment, with the actions the actor may use.
///
/// **The same feature, drawn twice.** `shipments_presentation_courier` renders
/// the same `ShipmentSummary` rows as a read-only stop list. Scenario 7 is
/// that neither package knows the other exists.
final class DispatcherBoardScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const DispatcherBoardScreen({required this.controller, super.key});

  /// What drives it.
  final DispatcherBoardController controller;

  @override
  State<DispatcherBoardScreen> createState() => _DispatcherBoardScreenState();

  /// How a status should be drawn on the board.
  ///
  /// Not the same mapping the courier's screen makes, and the difference is
  /// the point of the two packages existing. `undeliverable` is a warning to a
  /// courier — the visit is over and the parcel goes back, which is a normal
  /// outcome of a round — and a danger to a dispatcher, because on this screen
  /// it is a parcel somebody has to do something about today.
  ///
  /// Two screens over one feature disagreeing about what a state *means to the
  /// person looking at it* is exactly what a second presentation package is
  /// for. Neither could express it if the mapping lived in `shipments_api`.
  @visibleForTesting
  static PeykIntent intentOf(ShipmentStatus status) => switch (status) {
    ShipmentDeliveredToConsignee() => PeykIntent.success,
    ShipmentUndeliverable() => PeykIntent.danger,
    ShipmentAwaitingAssignment() => PeykIntent.warning,
    ShipmentOutForDelivery() ||
    ShipmentAssignedToCourier() ||
    ShipmentLoadedOnVehicle() ||
    ShipmentReturnedToDepot() => PeykIntent.neutral,
  };
}

class _DispatcherBoardScreenState extends State<DispatcherBoardScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(ShipmentsDispatcherStrings.title),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          BoardIdle() || BoardLoading() => const PeykLoadingView(),
          BoardReady(:final rows) when rows.isEmpty => PeykEmptyView(
            message: strings.resolve(ShipmentsDispatcherStrings.empty),
          ),
          BoardReady(:final rows, :final selected) => Column(
            children: [
              // Scenario 6, in one line. The button is not rendered at all
              // unless the port says the actor may use it. This screen has no
              // idea that identity has roles.
              if (widget.controller.canBulkAssign)
                PeykButton(
                  label: strings.resolve(
                    ShipmentsDispatcherStrings.bulkAssign,
                    arguments: {'count': selected.length},
                  ),
                  // Nothing selected is nothing to assign. Disabled rather
                  // than hidden: a button that comes and goes as rows are
                  // ticked is a button somebody reaches for and misses.
                  onPressed: selected.isEmpty ? null : () {},
                  tone: PeykButtonTone.primary,
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _BoardRow(
                    row: rows[index],
                    isSelected: selected.contains(rows[index].id),
                    onToggle: widget.controller.canAssign
                        ? () => widget.controller.toggle(rows[index].id)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          BoardFailed() => PeykFailureView(
            message: strings.resolve(
              ShipmentsDispatcherStrings.failureUnavailable,
            ),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
}

final class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.row,
    required this.isSelected,
    required this.onToggle,
  });

  final ShipmentSummary row;
  final bool isSelected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) => PeykOptionRow(
    label: row.consigneeName,
    selected: isSelected,
    onTap: onToggle,
  );
}
