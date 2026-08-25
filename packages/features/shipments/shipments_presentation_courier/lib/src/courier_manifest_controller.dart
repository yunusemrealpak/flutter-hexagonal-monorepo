import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

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
/// A `ChangeNotifier` rather than a bloc, and that is a deliberate
/// non-decision: no state management library is a dependency of this workspace
/// yet, and introducing one here would make every feature inherit the choice.
/// The state type beside this class is the part that matters — swapping in a
/// bloc, a cubit or a signal changes this file and nothing else, because a
/// widget renders `CourierManifestState` and does not know what produced it.
final class CourierManifestController extends ChangeNotifier {
  /// Creates the controller over its two ports.
  CourierManifestController({
    required this._shipments,
    required this._session,
  });

  final ShipmentsFacade _shipments;
  final SessionReader _session;

  CourierManifestState _state = const ManifestIdle();

  /// What the screen should be showing.
  CourierManifestState get state => _state;

  /// Fetches the signed-in courier's manifest.
  ///
  /// Does nothing when nobody is signed in. A screen behind a route that
  /// requires a session should never reach this, and asking for "nobody's
  /// manifest" would be a request the operation has to answer with an error
  /// the user cannot act on.
  Future<void> load() async {
    final actor = _session.current?.actor.id;
    if (actor == null) return;

    _emit(const ManifestLoading());

    final manifest = await _shipments.manifestFor(actor);
    _emit(
      switch (manifest) {
        Success(value: final rows) => ManifestReady(rows),
        Failed(:final failure) => ManifestFailed(failure),
      },
    );
  }

  void _emit(CourierManifestState next) {
    _state = next;
    notifyListeners();
  }
}
