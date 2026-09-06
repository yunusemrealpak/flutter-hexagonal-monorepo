import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// What the courier's stop list can be showing.
///
/// Sealed and hand-written, in a package that has no code generation at all. A
/// presentation package with four small state cases and no annotated type gets
/// no `build.yaml` and no `build_runner` dependency, which CLAUDE.md §7.6
/// calls the cheapest configuration rather than a missing one.
///
/// Four cases rather than one class with `isLoading`, `rows` and `failure` on
/// it. The flat shape lets a widget be handed a loading state that also has
/// rows and a failure, and the day two of those are set at once nobody can say
/// what should be on screen. Here the compiler answers it.
sealed class CourierManifestState {
  const CourierManifestState();
}

/// Nothing has been asked for yet.
final class ManifestIdle extends CourierManifestState {
  /// Creates the state.
  const ManifestIdle();
}

/// The manifest is being fetched.
final class ManifestLoading extends CourierManifestState {
  /// Creates the state.
  const ManifestLoading();
}

/// The manifest arrived.
///
/// [rows] may be empty, and that is a different thing from [ManifestFailed]:
/// "nothing assigned to you yet" is an ordinary morning, and showing an error
/// for it would have couriers calling the depot before their first parcel.
final class ManifestReady extends CourierManifestState {
  /// Creates the state.
  const ManifestReady(
    this.rows, {
    this.resume,
    this.loadingMore = false,
    this.moreFailure,
  });

  /// The stops, in the order the operation sent them.
  ///
  /// Every page fetched so far, concatenated. The screen renders what has
  /// arrived rather than one page at a time — a courier scrolling their round
  /// is walking one list, and page boundaries are an artefact of how it was
  /// fetched.
  final List<ShipmentSummary> rows;

  /// What to ask for next, or `null` when the manifest is exhausted.
  ///
  /// A whole `PageRequest` rather than a bare cursor, so the limit the caller
  /// chose travels with it. A controller that rebuilt the request from a
  /// default would silently change page size half way down a list.
  final PageRequest? resume;

  /// Whether the next page is in flight.
  final bool loadingMore;

  /// Why the last attempt at the next page failed, or `null`.
  ///
  /// **Beside the rows rather than replacing them.** A failed second page has
  /// not invalidated the first: dropping to [ManifestFailed] would take a
  /// courier's whole visible round away because the twenty-first stop did not
  /// arrive, and that is the mistake this field exists to make impossible.
  final ShipmentFailure? moreFailure;

  /// Whether asking again would produce anything.
  bool get hasMore => resume != null;

  /// Returns a copy with the given fields replaced.
  ///
  /// [rows] and [resume] are replaced when given and kept otherwise; the two
  /// transient fields are dropped unless passed, because they describe one
  /// attempt rather than the list.
  ManifestReady copyWith({
    List<ShipmentSummary>? rows,
    PageRequest? resume,
    bool loadingMore = false,
    ShipmentFailure? moreFailure,
  }) => ManifestReady(
    rows ?? this.rows,
    resume: resume ?? this.resume,
    loadingMore: loadingMore,
    moreFailure: moreFailure,
  );
}

/// The manifest could not be fetched.
final class ManifestFailed extends CourierManifestState {
  /// Creates the state.
  const ManifestFailed(this.failure);

  /// What went wrong, in shipments' own words.
  ///
  /// A `ShipmentFailure`, not a `String`. Turning it into a message is this
  /// layer's job and it happens at the widget, where the locale is known;
  /// carrying a formatted string here would put English in a state object and
  /// make it untranslatable a phase later.
  final ShipmentFailure failure;
}
