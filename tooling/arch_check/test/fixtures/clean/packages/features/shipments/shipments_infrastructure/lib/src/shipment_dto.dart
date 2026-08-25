import 'package:json_annotation/json_annotation.dart';

part 'shipment_dto.g.dart';

/// The wire shape, which never crosses into the domain.
@JsonSerializable()
class ShipmentDto {
  /// Creates the DTO.
  const ShipmentDto({required this.id});

  /// Reads one from JSON.
  factory ShipmentDto.fromJson(Map<String, dynamic> json) =>
      _$ShipmentDtoFromJson(json);

  /// The shipment's identifier as the server spells it.
  final String id;
}
