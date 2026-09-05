// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => SessionDto(
  actor: json['actor'] == null
      ? null
      : ActorDto.fromJson(json['actor'] as Map<String, dynamic>),
  accessToken: json['accessToken'] as String?,
  expiresAt: json['expiresAt'] as String?,
  refreshableUntil: json['refreshableUntil'] as String?,
  device: json['device'] == null
      ? null
      : DeviceBindingDto.fromJson(json['device'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionDtoToJson(SessionDto instance) =>
    <String, dynamic>{
      'actor': instance.actor?.toJson(),
      'accessToken': instance.accessToken,
      'expiresAt': instance.expiresAt,
      'refreshableUntil': instance.refreshableUntil,
      'device': instance.device?.toJson(),
    };

ActorDto _$ActorDtoFromJson(Map<String, dynamic> json) => ActorDto(
  id: json['id'] as String?,
  displayName: json['displayName'] as String?,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  grants: (json['grants'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ActorDtoToJson(ActorDto instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'roles': instance.roles,
  'grants': instance.grants,
};

DeviceBindingDto _$DeviceBindingDtoFromJson(Map<String, dynamic> json) =>
    DeviceBindingDto(
      deviceId: json['deviceId'] as String?,
      fingerprint: json['fingerprint'] as String?,
      boundAt: json['boundAt'] as String?,
    );

Map<String, dynamic> _$DeviceBindingDtoToJson(DeviceBindingDto instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'fingerprint': instance.fingerprint,
      'boundAt': instance.boundAt,
    };
