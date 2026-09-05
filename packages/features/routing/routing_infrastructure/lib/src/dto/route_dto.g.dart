// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'route_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StopDto _$StopDtoFromJson(Map<String, dynamic> json) => StopDto(
  id: json['id'] as String?,
  shipmentId: json['shipmentId'] as String?,
  label: json['label'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  serviceSeconds: (json['serviceSeconds'] as num?)?.toInt(),
  windowOpensAt: json['windowOpensAt'] as String?,
  windowClosesAt: json['windowClosesAt'] as String?,
);

Map<String, dynamic> _$StopDtoToJson(StopDto instance) => <String, dynamic>{
  'id': instance.id,
  'shipmentId': instance.shipmentId,
  'label': instance.label,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'serviceSeconds': instance.serviceSeconds,
  'windowOpensAt': instance.windowOpensAt,
  'windowClosesAt': instance.windowClosesAt,
};

RoutePlanDto _$RoutePlanDtoFromJson(Map<String, dynamic> json) => RoutePlanDto(
  id: json['id'] as String?,
  courier: json['courier'] as String?,
  originLatitude: (json['originLatitude'] as num?)?.toDouble(),
  originLongitude: (json['originLongitude'] as num?)?.toDouble(),
  departAt: json['departAt'] as String?,
  freeFlowKmh: (json['freeFlowKmh'] as num?)?.toDouble(),
  congestion: (json['congestion'] as num?)?.toDouble(),
  stops: (json['stops'] as List<dynamic>?)
      ?.map((e) => StopDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  order: (json['order'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$RoutePlanDtoToJson(RoutePlanDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courier': instance.courier,
      'originLatitude': instance.originLatitude,
      'originLongitude': instance.originLongitude,
      'departAt': instance.departAt,
      'freeFlowKmh': instance.freeFlowKmh,
      'congestion': instance.congestion,
      'stops': instance.stops?.map((e) => e.toJson()).toList(),
      'order': instance.order,
    };

SolveRequestDto _$SolveRequestDtoFromJson(Map<String, dynamic> json) =>
    SolveRequestDto(
      originLatitude: (json['originLatitude'] as num).toDouble(),
      originLongitude: (json['originLongitude'] as num).toDouble(),
      departAt: json['departAt'] as String,
      freeFlowKmh: (json['freeFlowKmh'] as num).toDouble(),
      congestion: (json['congestion'] as num).toDouble(),
      stops: (json['stops'] as List<dynamic>)
          .map((e) => StopDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      mustStartAt: json['mustStartAt'] as String?,
      mustEndAt: json['mustEndAt'] as String?,
    );

Map<String, dynamic> _$SolveRequestDtoToJson(SolveRequestDto instance) =>
    <String, dynamic>{
      'originLatitude': instance.originLatitude,
      'originLongitude': instance.originLongitude,
      'departAt': instance.departAt,
      'freeFlowKmh': instance.freeFlowKmh,
      'congestion': instance.congestion,
      'stops': instance.stops.map((e) => e.toJson()).toList(),
      'mustStartAt': instance.mustStartAt,
      'mustEndAt': instance.mustEndAt,
    };

SolveResponseDto _$SolveResponseDtoFromJson(Map<String, dynamic> json) =>
    SolveResponseDto(
      order: (json['order'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SolveResponseDtoToJson(SolveResponseDto instance) =>
    <String, dynamic>{'order': instance.order};

TrafficDto _$TrafficDtoFromJson(Map<String, dynamic> json) => TrafficDto(
  freeFlowKmh: (json['freeFlowKmh'] as num?)?.toDouble(),
  congestion: (json['congestion'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TrafficDtoToJson(TrafficDto instance) =>
    <String, dynamic>{
      'freeFlowKmh': instance.freeFlowKmh,
      'congestion': instance.congestion,
    };
