import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// What the dispatcher's board can be showing.
///
/// The same four shapes as the courier's stop list, and deliberately not
/// shared with it. They look alike today and diverge the moment the board
/// grows a selection, a filter or a sort — and the shared type would then have
/// three fields the courier's screen never sets. Two features that happen to
/// have the same state shape are not the same feature, and a `shared` package
/// for it is exactly the mistake the constitution forbids.
sealed class DispatcherBoardState {
  const DispatcherBoardState();
}

/// Nothing has been asked for yet.
final class BoardIdle extends DispatcherBoardState {
  /// Creates the state.
  const BoardIdle();
}

/// The board is being fetched.
final class BoardLoading extends DispatcherBoardState {
  /// Creates the state.
  const BoardLoading();
}

/// The board arrived.
final class BoardReady extends DispatcherBoardState {
  /// Creates the state.
  const BoardReady({
    required this.rows,
    this.selected = const {},
    this.resume,
    this.loadingMore = false,
    this.moreFailure,
  });

  /// Every shipment fetched so far.
  final List<ShipmentSummary> rows;

  /// The identifiers the dispatcher has ticked, for a bulk action.
  ///
  /// **Kept across a page load, and that is the one thing paging costs this
  /// screen.** A dispatcher ticks eight rows, fetches the next page, and has
  /// to still have eight ticked — so the selection lives beside the rows
  /// rather than being derived from them, and every copy carries it forward.
  /// It can therefore name a row that is no longer on screen after a reload;
  /// `assignSelected` sends identifiers, so that is harmless, and the
  /// alternative — pruning the selection to the visible rows — would silently
  /// drop a dispatcher's ticks when a page arrived.
  final Set<String> selected;

  /// What to ask for next, or `null` when the board is exhausted.
  final PageRequest? resume;

  /// Whether the next page is in flight.
  final bool loadingMore;

  /// Why the last attempt at the next page failed, or `null`.
  ///
  /// Beside the rows rather than replacing them: a failed third page has not
  /// invalidated the two hundred rows a dispatcher is already working through.
  final ShipmentFailure? moreFailure;

  /// Whether asking again would produce anything.
  bool get hasMore => resume != null;

  /// Returns a copy with [selected] replaced.
  BoardReady withSelection(Set<String> selection) =>
      copyWith(selected: selection);

  /// Returns a copy with the given fields replaced.
  ///
  /// The two transient fields are dropped unless passed, because they describe
  /// one attempt at one page rather than the board.
  BoardReady copyWith({
    List<ShipmentSummary>? rows,
    Set<String>? selected,
    PageRequest? resume,
    bool loadingMore = false,
    ShipmentFailure? moreFailure,
  }) => BoardReady(
    rows: rows ?? this.rows,
    selected: selected ?? this.selected,
    resume: resume ?? this.resume,
    loadingMore: loadingMore,
    moreFailure: moreFailure,
  );
}

/// The board could not be fetched.
final class BoardFailed extends DispatcherBoardState {
  /// Creates the state.
  const BoardFailed(this.failure);

  /// What went wrong, in shipments' own words.
  final ShipmentFailure failure;
}
