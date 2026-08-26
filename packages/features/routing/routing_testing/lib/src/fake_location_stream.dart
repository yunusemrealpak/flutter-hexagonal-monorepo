import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

/// A `LocationStreamPort` a test drives by hand.
///
/// Positions are pushed rather than generated, which is what makes a deviation
/// test a statement — *"the courier is now in the wrong district"* — instead of
/// a simulation whose outcome depends on how long the test ran.
///
/// The stream carries no failures, matching the port: a position that cannot
/// be fixed is simply not emitted. A stream that errored would tear down every
/// listener the first time a courier walked into a car park.
final class FakeLocationStream implements LocationStreamPort {
  /// Creates the fake, optionally at a known position.
  FakeLocationStream({GeoPoint? at}) : _current = at;

  final StreamController<GeoPoint> _positions =
      StreamController<GeoPoint>.broadcast();

  GeoPoint? _current;
  RoutingFailure? _failure;

  /// Moves the device to [position] and tells anyone watching.
  void moveTo(GeoPoint position) {
    _current = position;
    _failure = null;
    _positions.add(position);
  }

  /// Makes [current] fail until [moveTo] is called again.
  ///
  /// A denied permission and a device that cannot see the sky both arrive
  /// here, which is the branch a use case has to handle without a plan.
  // ignore: use_setters_to_change_properties
  void failsWith(RoutingFailure failure) => _failure = failure;

  @override
  Future<Result<GeoPoint, RoutingFailure>> current() async {
    final failure = _failure;
    if (failure != null) return Failed(failure);

    final position = _current;
    if (position == null) {
      return const Failed(
        PositionUnavailable(detail: 'no fix yet'),
      );
    }
    return Success(position);
  }

  @override
  Stream<GeoPoint> positions() => _positions.stream;

  /// Releases the stream.
  Future<void> dispose() => _positions.close();
}
