import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'fix_accuracy.dart';
import 'geo_fix.dart';
import 'location_failure.dart';
import 'location_source.dart';

/// A [LocationSource] that answers from the test instead of from a GPS.
///
/// It ships from this package rather than from `core_testing` for the same
/// reason `FakeHttpTransport` ships from `http_dio`: a fake belongs with the
/// contract it imitates.
///
/// [queue] is what makes retry and degradation testable — enqueue a timeout,
/// then a fix, and assert that the caller tried again rather than giving up.
/// [emit] pushes onto the tracking stream, so a test can walk a courier along
/// a route one position at a time without waiting for anything.
final class FakeLocationSource implements LocationSource {
  final List<Result<GeoFix, LocationFailure>> _queued = [];
  final StreamController<Result<GeoFix, LocationFailure>> _tracked =
      StreamController<Result<GeoFix, LocationFailure>>.broadcast();

  /// Every [currentFix] call's accuracy, oldest first.
  final List<FixAccuracy> requestedAccuracies = [];

  /// Whether [track] was asked for background permission.
  bool? trackedInBackground;

  /// Makes the next [currentFix] answer with [result].
  void queue(Result<GeoFix, LocationFailure> result) => _queued.add(result);

  /// Pushes [result] to everyone currently tracking.
  void emit(Result<GeoFix, LocationFailure> result) => _tracked.add(result);

  /// Closes the tracking stream.
  Future<void> dispose() => _tracked.close();

  @override
  Future<Result<GeoFix, LocationFailure>> currentFix({
    FixAccuracy accuracy = FixAccuracy.balanced,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    requestedAccuracies.add(accuracy);
    if (_queued.isEmpty) {
      // Failing rather than throwing keeps the fake honest to the contract it
      // implements, and the detail names what the test forgot.
      return const Failed(
        LocationUnavailable(detail: 'FakeLocationSource had nothing queued'),
      );
    }
    return _queued.removeAt(0);
  }

  @override
  Stream<Result<GeoFix, LocationFailure>> track({
    FixAccuracy accuracy = FixAccuracy.balanced,
    int distanceFilterMetres = 25,
    bool inBackground = false,
  }) {
    requestedAccuracies.add(accuracy);
    trackedInBackground = inBackground;
    return _tracked.stream;
  }
}
