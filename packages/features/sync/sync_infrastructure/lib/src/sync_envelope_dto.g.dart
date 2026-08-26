// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'sync_envelope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncEnvelopeDto _$SyncEnvelopeDtoFromJson(Map<String, dynamic> json) =>
    SyncEnvelopeDto(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: json['payload'] as String,
      policy: json['policy'] as String,
      queuedAt: json['queuedAt'] as String,
      attempt: (json['attempt'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$SyncEnvelopeDtoToJson(SyncEnvelopeDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'payload': instance.payload,
      'policy': instance.policy,
      'queuedAt': instance.queuedAt,
      'attempt': instance.attempt,
      'cursor': instance.cursor,
    };

SyncAckDto _$SyncAckDtoFromJson(Map<String, dynamic> json) => SyncAckDto(
  cursor: json['cursor'] as String?,
  conflict: json['conflict'] as bool?,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$SyncAckDtoToJson(SyncAckDto instance) =>
    <String, dynamic>{
      'cursor': instance.cursor,
      'conflict': instance.conflict,
      'reason': instance.reason,
    };

ServerTimeDto _$ServerTimeDtoFromJson(Map<String, dynamic> json) =>
    ServerTimeDto(now: json['now'] as String?);

Map<String, dynamic> _$ServerTimeDtoToJson(ServerTimeDto instance) =>
    <String, dynamic>{'now': instance.now};
