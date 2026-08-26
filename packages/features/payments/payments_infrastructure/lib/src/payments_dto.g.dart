// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'payments_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentAttemptDto _$PaymentAttemptDtoFromJson(Map<String, dynamic> json) =>
    PaymentAttemptDto(
      idempotencyKey: json['idempotencyKey'] as String?,
      shipmentId: json['shipmentId'] as String?,
      courierId: json['courierId'] as String?,
      minorUnits: (json['minorUnits'] as num?)?.toInt(),
      currency: json['currency'] as String?,
      method: json['method'] as String?,
      last4: json['last4'] as String?,
      transferReference: json['transferReference'] as String?,
      outcome: json['outcome'] as String?,
      takenAt: json['takenAt'] as String?,
      refundedAt: json['refundedAt'] as String?,
      refusalReason: json['refusalReason'] as String?,
    );

Map<String, dynamic> _$PaymentAttemptDtoToJson(PaymentAttemptDto instance) =>
    <String, dynamic>{
      'idempotencyKey': instance.idempotencyKey,
      'shipmentId': instance.shipmentId,
      'courierId': instance.courierId,
      'minorUnits': instance.minorUnits,
      'currency': instance.currency,
      'method': instance.method,
      'last4': instance.last4,
      'transferReference': instance.transferReference,
      'outcome': instance.outcome,
      'takenAt': instance.takenAt,
      'refundedAt': instance.refundedAt,
      'refusalReason': instance.refusalReason,
    };

SettlementDto _$SettlementDtoFromJson(Map<String, dynamic> json) =>
    SettlementDto(
      id: json['id'] as String?,
      courierId: json['courierId'] as String?,
      day: json['day'] as String?,
      currency: json['currency'] as String?,
      collectedMinorUnits: (json['collectedMinorUnits'] as num?)?.toInt(),
      refundedMinorUnits: (json['refundedMinorUnits'] as num?)?.toInt(),
      closedAt: json['closedAt'] as String?,
    );

Map<String, dynamic> _$SettlementDtoToJson(SettlementDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courierId': instance.courierId,
      'day': instance.day,
      'currency': instance.currency,
      'collectedMinorUnits': instance.collectedMinorUnits,
      'refundedMinorUnits': instance.refundedMinorUnits,
      'closedAt': instance.closedAt,
    };
