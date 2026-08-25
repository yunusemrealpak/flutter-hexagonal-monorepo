import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shipments_api/shipments_api.dart';

import 'dispatcher_board_controller.dart';
import 'dispatcher_board_state.dart';

/// The dispatcher's board: every shipment, with the actions the actor may use.
///
/// Deliberately plain — colours, typography and spacing come from
/// `design_system` in phase 7, and inventing them here would mean deleting
/// them then. What this widget shows now is the part that will not change: a
/// screen renders a sealed state exhaustively, and it asks a *port* whether an
/// action may be offered.
final class DispatcherBoardScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const DispatcherBoardScreen({required this.controller, super.key});

  /// What drives it.
  final DispatcherBoardController controller;

  @override
  State<DispatcherBoardScreen> createState() => _DispatcherBoardScreenState();
}

class _DispatcherBoardScreenState extends State<DispatcherBoardScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      BoardIdle() || BoardLoading() => const Center(
        child: Text('Loading the board'),
      ),
      BoardReady(:final rows, :final selected) => Column(
        children: [
          // Scenario 6, in one line. The button is not rendered at all
          // unless the port says the actor may use it. This screen has
          // no idea that identity has roles.
          if (widget.controller.canBulkAssign)
            Text('Assign ${selected.length} selected'),
          Expanded(
            child: ListView(
              children: [
                for (final row in rows)
                  _BoardRow(
                    row: row,
                    isSelected: selected.contains(row.id),
                    onToggle: widget.controller.canAssign
                        ? () => widget.controller.toggle(row.id)
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
      BoardFailed() => const Center(
        child: Text('The board could not be loaded.'),
      ),
    },
  );
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(isSelected ? '[x]' : '[ ]'),
          const SizedBox(width: 8),
          Expanded(child: Text(row.consigneeName)),
          Text(row.status.label),
        ],
      ),
    ),
  );
}
