import 'package:core_kernel/core_kernel.dart';

import '../failures/routing_failure.dart';

/// How long a courier spends at a stop once they have arrived.
///
/// Parking, finding the door, waiting for someone to answer, getting a
/// signature. It is the part of a route that has nothing to do with driving
/// and everything to do with whether the day's plan is achievable — a
/// twenty-stop route with eight minutes of service time per stop spends more
/// than two hours standing still, and an optimiser that ignored it would
/// produce ETAs that are wrong by that much and rising.
///
/// A wrapper rather than a bare `Duration`, so that a service time cannot be
/// passed where a travel time is meant. Both are durations; only one of them
/// changes when traffic does.
final class ServiceTime extends ValueObject<Duration> {
  const ServiceTime._(super.value);

  /// The default when a stop says nothing about itself.
  ///
  /// Five minutes, and it is a *product* guess rather than a measurement —
  /// which is why it is named here instead of appearing as a literal in
  /// whichever optimiser was written first.
  static const ServiceTime standard = ServiceTime._(Duration(minutes: 5));

  /// Reads a service time, refusing one no shift could absorb.
  ///
  /// The upper bound is not pedantry: a service time of a day, arriving from a
  /// mis-parsed field, would push every subsequent ETA past midnight and make
  /// the whole route look infeasible for a reason nobody could find.
  static Result<ServiceTime, RoutingFailure> of(Duration duration) {
    if (duration.isNegative) {
      return const Failed(
        MalformedRouteValue(field: 'serviceTime', reason: 'is negative'),
      );
    }
    if (duration > const Duration(hours: 4)) {
      return Failed(
        MalformedRouteValue(
          field: 'serviceTime',
          reason: '${duration.inMinutes} minutes is longer than any stop',
        ),
      );
    }
    return Success(ServiceTime._(duration));
  }
}
