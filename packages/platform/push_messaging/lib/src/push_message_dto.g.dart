// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'push_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushMessageDto _$PushMessageDtoFromJson(Map<String, dynamic> json) =>
    PushMessageDto(
      kind: json['kind'] as String,
      shipmentId: json['shipment_id'] as String?,
      threadId: json['thread_id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
    );
