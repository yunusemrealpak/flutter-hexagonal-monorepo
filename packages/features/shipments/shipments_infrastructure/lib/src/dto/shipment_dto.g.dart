// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'shipment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentDto _$ShipmentDtoFromJson(Map<String, dynamic> json) => ShipmentDto(
  id: json['id'] as String?,
  barcode: json['barcode'] as String?,
  status: json['status'] == null
      ? null
      : ShipmentStatusDto.fromJson(json['status'] as Map<String, dynamic>),
  consignee: json['consignee'] == null
      ? null
      : ConsigneeDto.fromJson(json['consignee'] as Map<String, dynamic>),
  history: (json['history'] as List<dynamic>?)
      ?.map((e) => StatusTransitionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShipmentDtoToJson(ShipmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'status': instance.status?.toJson(),
      'consignee': instance.consignee?.toJson(),
      'history': instance.history?.map((e) => e.toJson()).toList(),
    };

ShipmentStatusDto _$ShipmentStatusDtoFromJson(Map<String, dynamic> json) =>
    ShipmentStatusDto(
      kind: json['kind'] as String?,
      courier: json['courier'] as String?,
      proofReference: json['proofReference'] as String?,
      reason: json['reason'] as String?,
      at: json['at'] as String?,
    );

Map<String, dynamic> _$ShipmentStatusDtoToJson(ShipmentStatusDto instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'courier': instance.courier,
      'proofReference': instance.proofReference,
      'reason': instance.reason,
      'at': instance.at,
    };

ConsigneeDto _$ConsigneeDtoFromJson(Map<String, dynamic> json) => ConsigneeDto(
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] == null
      ? null
      : AddressDto.fromJson(json['address'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConsigneeDtoToJson(ConsigneeDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address?.toJson(),
    };

AddressDto _$AddressDtoFromJson(Map<String, dynamic> json) => AddressDto(
  formatted: json['formatted'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AddressDtoToJson(AddressDto instance) =>
    <String, dynamic>{
      'formatted': instance.formatted,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

StatusTransitionDto _$StatusTransitionDtoFromJson(Map<String, dynamic> json) =>
    StatusTransitionDto(
      from: json['from'] == null
          ? null
          : ShipmentStatusDto.fromJson(json['from'] as Map<String, dynamic>),
      to: json['to'] == null
          ? null
          : ShipmentStatusDto.fromJson(json['to'] as Map<String, dynamic>),
      at: json['at'] as String?,
      by: json['by'] as String?,
    );

Map<String, dynamic> _$StatusTransitionDtoToJson(
  StatusTransitionDto instance,
) => <String, dynamic>{
  'from': instance.from?.toJson(),
  'to': instance.to?.toJson(),
  'at': instance.at,
  'by': instance.by,
};

ShipmentSummaryDto _$ShipmentSummaryDtoFromJson(Map<String, dynamic> json) =>
    ShipmentSummaryDto(
      id: json['id'] as String?,
      barcode: json['barcode'] as String?,
      status: json['status'] == null
          ? null
          : ShipmentStatusDto.fromJson(json['status'] as Map<String, dynamic>),
      consigneeName: json['consigneeName'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$ShipmentSummaryDtoToJson(ShipmentSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'barcode': instance.barcode,
      'status': instance.status?.toJson(),
      'consigneeName': instance.consigneeName,
      'address': instance.address,
    };
