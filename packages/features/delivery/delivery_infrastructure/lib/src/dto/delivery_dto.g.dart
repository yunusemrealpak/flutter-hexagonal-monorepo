// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'delivery_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofDto _$ProofDtoFromJson(Map<String, dynamic> json) => ProofDto(
  recipientName: json['recipientName'] as String?,
  recipientRelationship: json['recipientRelationship'] as String?,
  capturedAt: json['capturedAt'] as String?,
  signatureBase64: json['signatureBase64'] as String?,
  signatureCapturedAt: json['signatureCapturedAt'] as String?,
  photoBase64: json['photoBase64'] as String?,
  photoMimeType: json['photoMimeType'] as String?,
  photoCapturedAt: json['photoCapturedAt'] as String?,
  scanSymbol: json['scanSymbol'] as String?,
  scanAt: json['scanAt'] as String?,
);

Map<String, dynamic> _$ProofDtoToJson(ProofDto instance) => <String, dynamic>{
  'recipientName': instance.recipientName,
  'recipientRelationship': instance.recipientRelationship,
  'capturedAt': instance.capturedAt,
  'signatureBase64': instance.signatureBase64,
  'signatureCapturedAt': instance.signatureCapturedAt,
  'photoBase64': instance.photoBase64,
  'photoMimeType': instance.photoMimeType,
  'photoCapturedAt': instance.photoCapturedAt,
  'scanSymbol': instance.scanSymbol,
  'scanAt': instance.scanAt,
};

DeliveryAttemptDto _$DeliveryAttemptDtoFromJson(Map<String, dynamic> json) =>
    DeliveryAttemptDto(
      id: json['id'] as String?,
      shipmentId: json['shipmentId'] as String?,
      courierId: json['courierId'] as String?,
      grade: json['grade'] as String?,
      startedAt: json['startedAt'] as String?,
      settledAt: json['settledAt'] as String?,
      outcome: json['outcome'] as String?,
      proofReference: json['proofReference'] as String?,
      proof: json['proof'] == null
          ? null
          : ProofDto.fromJson(json['proof'] as Map<String, dynamic>),
      reason: json['reason'] as String?,
      reasonNote: json['reasonNote'] as String?,
      reasonRequestedFor: json['reasonRequestedFor'] as String?,
    );

Map<String, dynamic> _$DeliveryAttemptDtoToJson(DeliveryAttemptDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipmentId': instance.shipmentId,
      'courierId': instance.courierId,
      'grade': instance.grade,
      'startedAt': instance.startedAt,
      'settledAt': instance.settledAt,
      'outcome': instance.outcome,
      'proofReference': instance.proofReference,
      'proof': instance.proof?.toJson(),
      'reason': instance.reason,
      'reasonNote': instance.reasonNote,
      'reasonRequestedFor': instance.reasonRequestedFor,
    };

GeoTargetDto _$GeoTargetDtoFromJson(Map<String, dynamic> json) => GeoTargetDto(
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  allowedMetres: (json['allowedMetres'] as num?)?.toDouble(),
);

Map<String, dynamic> _$GeoTargetDtoToJson(GeoTargetDto instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'allowedMetres': instance.allowedMetres,
    };

ProofReferenceDto _$ProofReferenceDtoFromJson(Map<String, dynamic> json) =>
    ProofReferenceDto(reference: json['reference'] as String?);

Map<String, dynamic> _$ProofReferenceDtoToJson(ProofReferenceDto instance) =>
    <String, dynamic>{'reference': instance.reference};
