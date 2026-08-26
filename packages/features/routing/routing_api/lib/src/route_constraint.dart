import 'package:freezed_annotation/freezed_annotation.dart';

import 'stop_id.dart';

part 'route_constraint.freezed.dart';

/// A rule an optimiser has to respect while ordering stops.
///
/// A closed union rather than a bag of nullable fields on the request, so that
/// "no constraint" and "a constraint whose value happens to be null" cannot be
/// the same thing — and so that adding a fifth kind is a case rather than
/// another nullable field every implementation has to remember to read.
///
/// **What is deliberately not here: time windows.** A window is a fact about
/// the *place*, so it lives on `Stop` and every optimiser sees it whether or
/// not anybody asked for it. A window that travelled as a constraint could be
/// omitted by the caller and silently ignored by the implementation, which is
/// the failure mode where a pharmacy closes at six and the route arrives at
/// half past.
@freezed
sealed class RouteConstraint with _$RouteConstraint {
  const RouteConstraint._();

  /// The route has to begin at this stop.
  ///
  /// A depot, usually. Two of these naming different stops is a request no
  /// optimiser can satisfy, and reporting that is better than picking one.
  const factory RouteConstraint.mustStartAt(StopId stop) = MustStartAt;

  /// The route has to finish at this stop.
  const factory RouteConstraint.mustEndAt(StopId stop) = MustEndAt;

  /// The route may not contain more than this many stops.
  ///
  /// A vehicle's capacity, or a shift's length expressed the crude way. A
  /// request with more stops than this is unsatisfiable rather than truncated:
  /// silently dropping the last four parcels is a decision an optimiser is not
  /// entitled to make.
  const factory RouteConstraint.maxStops(int count) = MaxStops;

  /// The route's driving and service time may not exceed this.
  const factory RouteConstraint.maxDuration(Duration limit) = MaxDuration;

  /// A short, stable name for this constraint.
  ///
  /// Used in failure messages so that "unsatisfiable" says which one. Not for
  /// display: a screen localises, and a localisation key is not something a
  /// contract package should own.
  String get label => switch (this) {
    MustStartAt() => 'mustStartAt',
    MustEndAt() => 'mustEndAt',
    MaxStops() => 'maxStops',
    MaxDuration() => 'maxDuration',
  };
}
