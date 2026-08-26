import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'routing_failure.dart';

/// The span during which a stop will accept a delivery.
///
/// A pharmacy that closes at six, a building whose loading bay is only staffed
/// in the morning, a customer who asked for after four. The window is a fact
/// about the *place*, which is why it lives on the stop rather than in the
/// optimiser's constraints — every optimiser has to respect the same one, and
/// a window that travelled as a constraint could be dropped by whichever
/// implementation forgot it.
///
/// Both ends are inclusive. A courier who arrives exactly at closing time is
/// on time, and a boundary that said otherwise would fail a delivery on a
/// rounding difference between two clocks.
@immutable
final class TravelWindow {
  const TravelWindow._({required this.opensAt, required this.closesAt});

  /// Reads a window, refusing one that cannot be met.
  static Result<TravelWindow, RoutingFailure> between({
    required DateTime opensAt,
    required DateTime closesAt,
  }) {
    if (closesAt.isBefore(opensAt)) {
      return const Failed(
        MalformedRouteValue(
          field: 'travelWindow',
          reason: 'closes before it opens',
        ),
      );
    }
    return Success(
      TravelWindow._(opensAt: opensAt.toUtc(), closesAt: closesAt.toUtc()),
    );
  }

  /// The earliest a courier may arrive, in UTC.
  final DateTime opensAt;

  /// The latest, in UTC.
  final DateTime closesAt;

  /// Whether [instant] falls inside this window, ends included.
  bool admits(DateTime instant) {
    final at = instant.toUtc();
    return !at.isBefore(opensAt) && !at.isAfter(closesAt);
  }

  /// Whether arriving at [instant] is too late.
  ///
  /// Distinct from `!admits(instant)`: arriving early is not a failure, it is
  /// a wait. Collapsing the two would make an optimiser treat a courier who is
  /// ahead of schedule as one who has missed a delivery.
  bool isLateAt(DateTime instant) => instant.toUtc().isAfter(closesAt);

  /// How long a courier arriving at [instant] has to wait, if at all.
  Duration waitFrom(DateTime instant) {
    final at = instant.toUtc();
    return at.isBefore(opensAt) ? opensAt.difference(at) : Duration.zero;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelWindow &&
          other.opensAt == opensAt &&
          other.closesAt == closesAt;

  @override
  int get hashCode => Object.hash(opensAt, closesAt);

  @override
  String toString() => 'TravelWindow($opensAt..$closesAt)';
}
