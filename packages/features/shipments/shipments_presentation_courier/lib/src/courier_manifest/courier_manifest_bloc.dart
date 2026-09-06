import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'courier_manifest_event.dart';
import 'courier_manifest_state.dart';

/// Drives the courier's stop list.
///
/// It holds two ports and no implementations: `ShipmentsFacade` to ask for the
/// manifest and `SessionReader` to know whose manifest to ask for. Both are
/// declared in an `_api` package and both arrive through the constructor —
/// this package cannot depend on `shipments_application` or on anything of
/// identity's beyond its contract, so what it actually gets is decided by
/// whichever app composed it.
///
/// **`droppable()` on the next page *is* the in-flight guard.** The version
/// before this one carried a `state.loadingMore` check at the top of
/// `loadMore`, written because a list that asks for more when it is scrolled
/// asks several times in the same gesture — and without the check the second
/// request is issued from the same state as the first, the same page comes
/// back twice and is appended twice. That check was a transformer written by
/// hand, one call site at a time. The flag stays, because the tail row draws
/// a spinner from it, but it no longer decides anything.
///
/// **The first page is `restartable()`, and the difference from the next page
/// is the point.** Reading the manifest again means starting the walk over, so
/// a newer read makes an older one worthless. Fetching the next page twice
/// means asking for the same cursor twice, so the second is worth nothing at
/// all. Same feature, two reads, two policies.
final class CourierManifestBloc
    extends Bloc<CourierManifestEvent, CourierManifestState> {
  /// Creates the bloc over its two ports.
  CourierManifestBloc({required this._shipments, required this._session})
    : super(const ManifestIdle()) {
    on<ManifestRequested>(_onRequested, transformer: restartable());
    on<MoreRequested>(_onMoreRequested, transformer: droppable());
  }

  final ShipmentsFacade _shipments;
  final SessionReader _session;

  /// Fetches the signed-in courier's manifest.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this, and asking for "nobody's
  /// manifest" would be a request the operation has to answer with an error
  /// the user cannot act on.
  Future<void> _onRequested(
    ManifestRequested event,
    Emitter<CourierManifestState> emit,
  ) async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;

    emit(const ManifestLoading());

    const first = PageRequest();
    final manifest = await _shipments.manifestFor(actor, page: first);
    emit(
      switch (manifest) {
        Success(value: final page) => ManifestReady(
          page.items,
          resume: first.following(page),
        ),
        Failed(:final failure) => ManifestFailed(failure),
      },
    );
  }

  /// Fetches the page after the one on screen.
  ///
  /// Does nothing when there is nothing left, and nothing while a fetch is
  /// already out — the second of those is `droppable()` rather than a check
  /// written here.
  Future<void> _onMoreRequested(
    MoreRequested event,
    Emitter<CourierManifestState> emit,
  ) async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;
    if (state case final ManifestReady showing) {
      final resume = showing.resume;
      if (resume == null) return;

      emit(showing.copyWith(loadingMore: true));

      final manifest = await _shipments.manifestFor(actor, page: resume);
      emit(
        switch (manifest) {
          Success(value: final page) => ManifestReady(
            [...showing.rows, ...page.items],
            resume: resume.following(page),
          ),
          // The rows already on screen survive. A courier whose twenty-first
          // stop did not arrive still has twenty they can drive to, and
          // dropping to `ManifestFailed` would take those away as well.
          Failed(:final failure) => showing.copyWith(moreFailure: failure),
        },
      );
    }
  }
}
