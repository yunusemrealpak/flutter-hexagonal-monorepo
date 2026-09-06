import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shipments_api/shipments_api.dart';

import '../shipments_dispatcher_strings.dart';
import 'dispatcher_board_bloc.dart';
import 'dispatcher_board_event.dart';
import 'dispatcher_board_state.dart';

/// The dispatcher's board: every shipment, with the actions the actor may use.
///
/// **The same feature, drawn twice.** `shipments_presentation_courier` renders
/// the same `ShipmentSummary` rows as a read-only stop list. Scenario 7 is
/// that neither package knows the other exists.
///
/// **This is the screen where a selector saves the most.** A board is two
/// hundred rows and ticking one of them changes one tick — so the list is
/// rebuilt only when the rows themselves change, and each row subscribes to
/// the one `bool` that says whether it is ticked.
final class DispatcherBoardScreen extends StatefulWidget {
  /// Creates the screen. Its bloc comes from the tree above it.
  const DispatcherBoardScreen({super.key});

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
    context.read<DispatcherBoardBloc>().add(const BoardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(ShipmentsDispatcherStrings.title),
      body: BlocBuilder<DispatcherBoardBloc, DispatcherBoardState>(
        // Only when the rows themselves change. A tick, a page going out and
        // a failed assignment all emit a new `BoardReady` over the same list,
        // and each of those is drawn by a selector below.
        buildWhen: (previous, current) => switch ((previous, current)) {
          (BoardReady(rows: final before), BoardReady(rows: final after))
              when identical(before, after) =>
            false,
          _ => true,
        },
        builder: (context, state) => switch (state) {
          BoardIdle() || BoardLoading() => const PeykLoadingView(),
          BoardReady(:final rows, hasMore: false) when rows.isEmpty =>
            PeykEmptyView(
              message: strings.resolve(ShipmentsDispatcherStrings.empty),
            ),
          final BoardReady state => _Board(state: state),
          BoardFailed() => PeykFailureView(
            message: strings.resolve(
              ShipmentsDispatcherStrings.failureUnavailable,
            ),
            onRetry: () =>
                context.read<DispatcherBoardBloc>().add(const BoardRequested()),
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
  const _Board({required this.state});

  final BoardReady state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DispatcherBoardBloc>();
    final rows = state.rows;

    return Column(
      children: [
        // Scenario 6, in one line. The button is not rendered at all unless
        // the port says the actor may use it. This screen has no idea that
        // identity has roles.
        if (bloc.canBulkAssign) const _BulkAssign(),
        Expanded(
          child: ListView.builder(
            // The extra tail row when there is more, drawn as an affordance
            // rather than fetched from `itemBuilder`: asking for a page during
            // a build fires several requests in one scroll gesture, and the
            // bloc's `droppable()` should not be the only thing standing
            // between a board and four identical requests.
            itemCount: rows.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) => index == rows.length
                ? const _More()
                : _BoardRow(
                    row: rows[index],
                    canToggle: bloc.canAssign,
                  ),
          ),
        ),
      ],
    );
  }
}

/// The bulk action, and what the last one said if it did not finish.
///
/// The count in the label is what makes this its own subscription: a tick
/// changes it and changes nothing else on the board, so it is selected as an
/// `(int, String?)` and the two hundred rows below stay as they are.
final class _BulkAssign extends StatelessWidget {
  const _BulkAssign();

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return BlocSelector<
      DispatcherBoardBloc,
      DispatcherBoardState,
      (int, String?)
    >(
      selector: (state) => switch (state) {
        BoardReady(:final selected, :final assignFailure) => (
          selected.length,
          assignFailure == null
              ? null
              : strings.resolve(ShipmentsDispatcherStrings.assignFailed),
        ),
        _ => (0, null),
      },
      builder: (context, action) {
        final (count, failure) = action;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PeykButton(
              label: strings.resolve(
                ShipmentsDispatcherStrings.bulkAssign,
                arguments: {'count': count},
              ),
              // Nothing selected is nothing to assign. Disabled rather than
              // hidden: a button that comes and goes as rows are ticked is a
              // button somebody reaches for and misses.
              //
              // Enabled, it still does nothing here, and that gap is older
              // than this file's bloc: assigning needs a courier to assign
              // *to*, and this screen has no picker. An app that has one adds
              // `SelectionAssigned` to the bloc it already provided.
              onPressed: count == 0 ? null : () {},
              tone: PeykButtonTone.primary,
            ),
            // An assignment that stopped half way through. Beside the board
            // rather than replacing it: the ticks are still there and the same
            // selection can be sent again.
            if (failure != null) ...[
              const PeykGap.vertical(PeykGapSize.betweenLines),
              PeykChip(label: failure, intent: PeykIntent.danger),
            ],
          ],
        );
      },
    );
  }
}

/// The tail of the board: fetch the next page, or say why the last try did not.
final class _More extends StatelessWidget {
  const _More();

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return BlocSelector<
      DispatcherBoardBloc,
      DispatcherBoardState,
      (bool, bool)
    >(
      selector: (state) => switch (state) {
        BoardReady(:final loadingMore, :final moreFailure) => (
          loadingMore,
          moreFailure != null,
        ),
        _ => (false, false),
      },
      builder: (context, tail) {
        final (loadingMore, failed) = tail;
        if (loadingMore) return const PeykLoadingView();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (failed) ...[
              PeykChip(
                label: strings.resolve(ShipmentsDispatcherStrings.moreFailed),
                intent: PeykIntent.warning,
              ),
              const PeykGap.vertical(PeykGapSize.betweenLines),
            ],
            PeykButton(
              label: strings.resolve(ShipmentsDispatcherStrings.loadMore),
              onPressed: () => context.read<DispatcherBoardBloc>().add(
                const MoreRequested(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One row, subscribed to its own tick.
///
/// The whole argument for `BlocSelector` in one widget: ticking a row emits a
/// new `BoardReady` over the same rows, and without this every row on a board
/// of two hundred would rebuild to change one checkbox.
final class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.row, required this.canToggle});

  final ShipmentSummary row;
  final bool canToggle;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DispatcherBoardBloc>();

    return BlocSelector<DispatcherBoardBloc, DispatcherBoardState, bool>(
      selector: (state) =>
          state is BoardReady && state.selected.contains(row.id),
      builder: (context, isSelected) => PeykOptionRow(
        label: row.consigneeName,
        selected: isSelected,
        onTap: canToggle ? () => bloc.add(RowToggled(row.id)) : null,
      ),
    );
  }
}
