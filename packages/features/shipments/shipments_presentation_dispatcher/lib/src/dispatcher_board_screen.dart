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
          BoardReady(:final rows, hasMore: false) when rows.isEmpty =>
            PeykEmptyView(
              message: strings.resolve(ShipmentsDispatcherStrings.empty),
            ),
          final BoardReady state => _Board(
            state: state,
            controller: widget.controller,
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

/// The board itself: the bulk action, the rows, and the tail.
///
/// Extracted from the screen's switch because it needs the whole `BoardReady`
/// rather than two of its fields, and a case arm that binds five patterns is
/// one nobody reads.
final class _Board extends StatelessWidget {
  const _Board({required this.state, required this.controller});

  final BoardReady state;
  final DispatcherBoardController controller;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);
    final rows = state.rows;

    return Column(
      children: [
        // Scenario 6, in one line. The button is not rendered at all unless
        // the port says the actor may use it. This screen has no idea that
        // identity has roles.
        if (controller.canBulkAssign)
          PeykButton(
            label: strings.resolve(
              ShipmentsDispatcherStrings.bulkAssign,
              arguments: {'count': state.selected.length},
            ),
            // Nothing selected is nothing to assign. Disabled rather than
            // hidden: a button that comes and goes as rows are ticked is a
            // button somebody reaches for and misses.
            onPressed: state.selected.isEmpty ? null : () {},
            tone: PeykButtonTone.primary,
          ),
        Expanded(
          child: ListView.builder(
            // The extra tail row when there is more, drawn as an affordance
            // rather than fetched from `itemBuilder`: asking for a page during
            // a build fires several requests in one scroll gesture, and the
            // controller's in-flight guard should not be the only thing
            // standing between a board and four identical requests.
            itemCount: rows.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) => index == rows.length
                ? _More(
                    state: state,
                    onMore: () => unawaited(controller.loadMore()),
                  )
                : _BoardRow(
                    row: rows[index],
                    isSelected: state.selected.contains(rows[index].id),
                    onToggle: controller.canAssign
                        ? () => controller.toggle(rows[index].id)
                        : null,
                  ),
          ),
        ),
      ],
    );
  }
}

/// The tail of the board: fetch the next page, or say why the last try did not.
final class _More extends StatelessWidget {
  const _More({required this.state, required this.onMore});

  final BoardReady state;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    if (state.loadingMore) return const PeykLoadingView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.moreFailure != null) ...[
          PeykChip(
            label: strings.resolve(ShipmentsDispatcherStrings.moreFailed),
            intent: PeykIntent.warning,
          ),
          const PeykGap.vertical(PeykGapSize.betweenLines),
        ],
        PeykButton(
          label: strings.resolve(ShipmentsDispatcherStrings.loadMore),
          onPressed: onMore,
        ),
      ],
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
