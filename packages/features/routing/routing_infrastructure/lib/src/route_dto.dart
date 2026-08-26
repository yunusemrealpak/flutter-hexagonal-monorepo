import 'package:json_annotation/json_annotation.dart';

part 'route_dto.g.dart';

/// A stop exactly as the wire and the cache carry it.
///
/// One DTO serving two boundaries, which is a decision rather than an
/// accident: the solver's request and the device's cache describe the same
/// thing, and two shapes would drift apart the first time a field was added to
/// one of them.
///
/// Every field is nullable on purpose. What arrives is what the far side chose
/// to send — or what an older release of this app wrote to disk — and the
/// mapper is where an absent field becomes a named failure instead of a
/// `TypeError` thrown two layers up.
@JsonSerializable()
class StopDto {
  /// Creates the DTO.
  const StopDto({
    this.id,
    this.shipmentId,
    this.label,
    this.latitude,
    this.longitude,
    this.serviceSeconds,
    this.windowOpensAt,
    this.windowClosesAt,
  });

  /// Reads one from decoded JSON.
  factory StopDto.fromJson(Map<String, dynamic> json) =>
      _$StopDtoFromJson(json);

  /// The stop's identifier.
  final String? id;

  /// The parcel it is about, where there is one.
  final String? shipmentId;

  /// What a courier reads on a stop list.
  ///
  /// Named `label` rather than `address`, because that is what routing holds:
  /// a string it draws. Calling it an address would invite somebody to parse
  /// it, and parsing an address is `shipments`' job.
  final String? label;

  /// Degrees north.
  final double? latitude;

  /// Degrees east.
  final double? longitude;

  /// How long the courier will be there, in seconds.
  final int? serviceSeconds;

  /// When the place opens, ISO-8601, or absent for anytime.
  final String? windowOpensAt;

  /// When it closes.
  final String? windowClosesAt;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$StopDtoToJson(this);
}

/// A whole plan, as the device's cache stores it.
///
/// **The estimates are not here, and that is deliberate.** They are derived
/// from the order, the departure instant, the traffic profile and the stops'
/// service times — all four of which *are* stored. Persisting the derived
/// values as well would create a second source of truth, and the day the
/// estimate rule changed, a device would show yesterday's arithmetic until its
/// cache happened to be rewritten.
@JsonSerializable()
class RoutePlanDto {
  /// Creates the DTO.
  const RoutePlanDto({
    this.id,
    this.courier,
    this.originLatitude,
    this.originLongitude,
    this.departAt,
    this.freeFlowKmh,
    this.congestion,
    this.stops,
    this.order,
  });

  /// Reads one from decoded JSON.
  factory RoutePlanDto.fromJson(Map<String, dynamic> json) =>
      _$RoutePlanDtoFromJson(json);

  /// The plan's identifier.
  final String? id;

  /// Whose route it is.
  final String? courier;

  /// Where the courier starts, degrees north.
  final double? originLatitude;

  /// Degrees east.
  final double? originLongitude;

  /// When they leave, ISO-8601.
  final String? departAt;

  /// The speed the estimates were computed at.
  final double? freeFlowKmh;

  /// The congestion multiplier they were computed at.
  final double? congestion;

  /// Every stop on the route.
  final List<StopDto>? stops;

  /// The order they are visited in, by identifier.
  final List<String>? order;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$RoutePlanDtoToJson(this);
}

/// What the remote solver is asked.
@JsonSerializable()
class SolveRequestDto {
  /// Creates the DTO.
  const SolveRequestDto({
    required this.originLatitude,
    required this.originLongitude,
    required this.departAt,
    required this.freeFlowKmh,
    required this.congestion,
    required this.stops,
    this.mustStartAt,
    this.mustEndAt,
  });

  /// Reads one from decoded JSON.
  factory SolveRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SolveRequestDtoFromJson(json);

  /// Where the courier starts, degrees north.
  final double originLatitude;

  /// Degrees east.
  final double originLongitude;

  /// When they leave, ISO-8601.
  final String departAt;

  /// The speed to plan at.
  final double freeFlowKmh;

  /// The congestion multiplier to plan at.
  final double congestion;

  /// The stops to order.
  final List<StopDto> stops;

  /// The stop the route has to begin at, if one was named.
  final String? mustStartAt;

  /// The stop it has to end at.
  final String? mustEndAt;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SolveRequestDtoToJson(this);
}

/// What the remote solver answers.
///
/// One field, because that is all the port promises: an *order*. A solver that
/// also sent arrival times would be sending numbers this app throws away —
/// `RoutePlan` computes them, so that the device-side and server-side answers
/// cannot disagree about what "arrival" means.
@JsonSerializable()
class SolveResponseDto {
  /// Creates the DTO.
  const SolveResponseDto({this.order});

  /// Reads one from decoded JSON.
  factory SolveResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SolveResponseDtoFromJson(json);

  /// The stops, in the order the solver chose.
  final List<String>? order;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SolveResponseDtoToJson(this);
}

/// Traffic conditions on the wire.
@JsonSerializable()
class TrafficDto {
  /// Creates the DTO.
  const TrafficDto({this.freeFlowKmh, this.congestion});

  /// Reads one from decoded JSON.
  factory TrafficDto.fromJson(Map<String, dynamic> json) =>
      _$TrafficDtoFromJson(json);

  /// The speed on an empty road, kilometres per hour.
  final double? freeFlowKmh;

  /// How much longer a journey takes than it would on an empty road.
  final double? congestion;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$TrafficDtoToJson(this);
}
