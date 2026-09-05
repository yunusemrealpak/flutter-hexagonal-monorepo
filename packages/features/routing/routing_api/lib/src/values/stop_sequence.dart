import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../entities/stop.dart';
import '../failures/routing_failure.dart';
import 'stop_id.dart';

/// The order stops are visited in.
///
/// A type of its own rather than a `List<StopId>`, because there is something
/// to check and exactly one place worth checking it. A sequence is valid only
/// against a set of stops: it has to name each of them once, name nothing
/// else, and name nothing twice. All three of those are a route a courier
/// cannot drive, and all three are what a dispatcher's drag-and-drop can
/// produce on a bad afternoon.
///
/// This is also what makes `RouteOptimizerPort` testable as a contract. Every
/// implementation returns one of these, and the kit asserts the same three
/// properties of all of them — a local heuristic that dropped a stop and a
/// remote solver that dropped a stop fail the same assertion.
@immutable
final class StopSequence {
  const StopSequence._(this._order);

  /// A route with nothing on it.
  ///
  /// Not a failure. A courier with no assignments has an empty route, and an
  /// optimiser that refused to produce one would put an error on the screen of
  /// everybody who has not been given work yet.
  static const StopSequence empty = StopSequence._([]);

  /// Reads a sequence, checking it describes exactly [stops].
  static Result<StopSequence, RoutingFailure> over(
    List<Stop> stops,
    List<StopId> order,
  ) {
    final expected = stops.map((stop) => stop.id).toSet();
    final seen = <StopId>{};

    for (final id in order) {
      if (!seen.add(id)) {
        return Failed(
          SequenceDoesNotMatch(reason: '${id.value} appears more than once'),
        );
      }
      if (!expected.contains(id)) {
        return Failed(
          SequenceDoesNotMatch(reason: '${id.value} is not on this route'),
        );
      }
    }

    if (seen.length != expected.length) {
      final missing = expected
          .difference(seen)
          .map((id) => id.value)
          .join(', ');
      return Failed(
        SequenceDoesNotMatch(reason: 'nothing visits $missing'),
      );
    }

    return Success(StopSequence._(List<StopId>.unmodifiable(order)));
  }

  final List<StopId> _order;

  /// The stops, in the order they are visited.
  List<StopId> get order => _order;

  /// How many stops are on the route.
  int get length => _order.length;

  /// Whether there is nothing to drive.
  bool get isEmpty => _order.isEmpty;

  /// The first stop, or `null` on an empty route.
  StopId? get first => _order.isEmpty ? null : _order.first;

  /// The stop that follows [id], or `null` when [id] is last or absent.
  StopId? after(StopId id) {
    final index = _order.indexOf(id);
    if (index < 0 || index == _order.length - 1) return null;
    return _order[index + 1];
  }

  /// Where [id] falls, or `-1` when it is not on the route.
  int positionOf(StopId id) => _order.indexOf(id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopSequence &&
          other._order.length == _order.length &&
          _sameOrder(other._order);

  bool _sameOrder(List<StopId> other) {
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] != other[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_order);

  @override
  String toString() =>
      'StopSequence(${_order.map((id) => id.value).join(' -> ')})';
}
