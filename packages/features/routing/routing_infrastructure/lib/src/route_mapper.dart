import 'package:core_kernel/core_kernel.dart';
import 'package:routing_api/routing_api.dart';

import 'route_dto.dart';

/// Translates between the routing domain and the shapes that cross a wire or a
/// disk.
///
/// Hand-written, like every mapper in this workspace. What a generated one
/// would still have to be told is exactly what is in this file: that an absent
/// field is a named failure rather than a `TypeError`, that instants go out in
/// UTC, and that a value object gets to refuse its own input.
///
/// The `toUtc()` calls are the lines that are easy to omit and hard to notice
/// missing. A device set to Istanbul time would otherwise write local instants
/// that read back as UTC, and a plan restored after a restart would claim to
/// have departed three hours earlier than it did.
///
/// Every read is written as a `switch` that binds or returns. The shorter
/// spelling — `fold((v) => v, (_) => throw …)` — puts a throw on a branch the
/// author believes is unreachable, and a mapper is precisely the place where
/// that belief is being tested by somebody else's data.
///
/// **This file imports no foreign feature**, and that is not an accident of
/// what it happens to need. Section 2 forbids `feature_infrastructure` from
/// reaching another feature at all, contract included — so rebuilding the
/// `ActorId` and `ShipmentId` that routing's own contract is expressed in goes
/// through `CourierReference` and `ShipmentReference` in `routing_api`, which
/// is the one layer allowed to see them. What this mapper consumes is
/// *routing's* reading of a courier, complete with routing's failure type.
abstract final class RouteMapper {
  /// Turns a stop into the shape both the solver and the cache use.
  static StopDto stopToDto(Stop stop) => StopDto(
    id: stop.id.value,
    shipmentId: stop.shipmentId?.value,
    label: stop.label,
    latitude: stop.at.latitude,
    longitude: stop.at.longitude,
    serviceSeconds: stop.serviceTime.value.inSeconds,
    windowOpensAt: stop.window?.opensAt.toUtc().toIso8601String(),
    windowClosesAt: stop.window?.closesAt.toUtc().toIso8601String(),
  );

  /// Reads a stop back.
  ///
  /// One call into `Stop.place`, which is the whole point of that factory: the
  /// checks a stop has to pass live in the domain, and a mapper that repeated
  /// them would be a second place for them to drift.
  static Result<Stop, RoutingFailure> stopToDomain(StopDto dto) {
    final ServiceTime serviceTime;
    switch (ServiceTime.of(Duration(seconds: dto.serviceSeconds ?? 300))) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        serviceTime = value;
    }

    final TravelWindow? window;
    switch (_windowFrom(dto)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        window = value;
    }

    return Stop.place(
      id: dto.id ?? '',
      label: dto.label ?? '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      shipmentId: dto.shipmentId,
      serviceTime: serviceTime,
      window: window,
    );
  }

  /// Turns a plan into the shape the cache stores.
  static RoutePlanDto planToDto(RoutePlan plan) => RoutePlanDto(
    id: plan.id.value,
    courier: plan.courier.value,
    originLatitude: plan.origin.latitude,
    originLongitude: plan.origin.longitude,
    departAt: plan.departAt.toUtc().toIso8601String(),
    freeFlowKmh: plan.traffic.freeFlowKmh,
    congestion: plan.traffic.congestion,
    stops: [for (final stop in plan.stops) stopToDto(stop)],
    order: [for (final id in plan.sequence.order) id.value],
  );

  /// Reads a plan back, recomputing its estimates.
  ///
  /// `RoutePlan.of` does the recomputation, which is why the DTO stores no
  /// arrival times. Persisting them would put a second source of truth on the
  /// device, and the day the estimate rule changed a courier would see
  /// yesterday's arithmetic until their cache happened to be rewritten.
  static Result<RoutePlan, RoutingFailure> planToDomain(RoutePlanDto dto) {
    final RoutePlanId id;
    switch (RoutePlanId.parse(dto.id ?? '')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        id = value;
    }

    // Through routing's own reader rather than identity's parser. This
    // package may not see identity_api, and what it needs is not identity's
    // vocabulary but routing's answer to "is this a courier we can name?".
    //
    // Chained with flatMap rather than bound to a local, because a local would
    // have to be *declared* — `final ActorId courier;` — and writing that type
    // name is the one thing this file must not do. The lambda's parameter type
    // is inferred, which is the difference between not naming a type and not
    // depending on it.
    final courierRead = CourierReference.parse(dto.courier ?? '');
    if (courierRead case Failed(:final failure)) return Failed(failure);

    final GeoPoint origin;
    switch (GeoPoint.at(
      latitude: dto.originLatitude ?? double.nan,
      longitude: dto.originLongitude ?? double.nan,
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        origin = value;
    }

    final stops = <Stop>[];
    for (final stopDto in dto.stops ?? const <StopDto>[]) {
      switch (stopToDomain(stopDto)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          stops.add(value);
      }
    }

    final order = <StopId>[];
    for (final raw in dto.order ?? const <String>[]) {
      switch (StopId.parse(raw)) {
        case Failed(:final failure):
          return Failed(failure);
        case Success(:final value):
          order.add(value);
      }
    }

    final StopSequence sequence;
    switch (StopSequence.over(stops, order)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        sequence = value;
    }

    final DateTime departAt;
    switch (_instant(dto.departAt, 'plan.departAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        departAt = value;
    }

    final TrafficProfile traffic;
    switch (TrafficProfile.of(
      freeFlowKmh: dto.freeFlowKmh ?? TrafficProfile.assumed.freeFlowKmh,
      congestion: dto.congestion ?? TrafficProfile.assumed.congestion,
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        traffic = value;
    }

    return courierRead.flatMap(
      (courier) => RoutePlan.of(
        id: id,
        courier: courier,
        origin: origin,
        stops: stops,
        sequence: sequence,
        departAt: departAt,
        traffic: traffic,
      ),
    );
  }

  /// Turns a request into the body the solver is sent.
  static SolveRequestDto solveRequest(OptimisationRequest request) =>
      SolveRequestDto(
        originLatitude: request.origin.latitude,
        originLongitude: request.origin.longitude,
        departAt: request.departAt.toUtc().toIso8601String(),
        freeFlowKmh: request.traffic.freeFlowKmh,
        congestion: request.traffic.congestion,
        stops: [for (final stop in request.stops) stopToDto(stop)],
        mustStartAt: request.constraints.requiredStart?.value,
        mustEndAt: request.constraints.requiredEnd?.value,
      );

  /// Reads a traffic profile from the wire.
  ///
  /// Missing fields fall back to the assumed profile rather than failing. A
  /// traffic service that answers with half a profile is having a bad day, and
  /// refusing to plan because of it would leave a courier with no route over a
  /// number that was going to be approximate anyway.
  static Result<TrafficProfile, RoutingFailure> trafficToDomain(
    TrafficDto dto,
  ) => TrafficProfile.of(
    freeFlowKmh: dto.freeFlowKmh ?? TrafficProfile.assumed.freeFlowKmh,
    congestion: dto.congestion ?? TrafficProfile.assumed.congestion,
  );

  static Result<TravelWindow?, RoutingFailure> _windowFrom(StopDto dto) {
    final opens = dto.windowOpensAt;
    final closes = dto.windowClosesAt;
    if (opens == null || closes == null) return const Success(null);

    final DateTime opensAt;
    switch (_instant(opens, 'stop.windowOpensAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        opensAt = value;
    }

    final DateTime closesAt;
    switch (_instant(closes, 'stop.windowClosesAt')) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        closesAt = value;
    }

    return TravelWindow.between(
      opensAt: opensAt,
      closesAt: closesAt,
    ).map<TravelWindow?>((window) => window);
  }

  /// Reads an instant, catching the one exception this package allows itself.
  ///
  /// A far side that sends an unparseable timestamp is the far side's mistake,
  /// and the alternative to catching is letting a `FormatException` cross a
  /// port boundary — which invariant 1.2.9 forbids and which would reach a use
  /// case that has no way to handle it.
  static Result<DateTime, RoutingFailure> _instant(String? raw, String field) {
    if (raw == null) {
      return Failed(MalformedRouteValue(field: field, reason: 'is missing'));
    }
    try {
      return Success(DateTime.parse(raw).toUtc());
    } on FormatException {
      return Failed(
        MalformedRouteValue(field: field, reason: 'is not an instant: $raw'),
      );
    }
  }
}
