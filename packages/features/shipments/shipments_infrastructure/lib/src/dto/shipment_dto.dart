import 'package:json_annotation/json_annotation.dart';

part 'shipment_dto.g.dart';

/// A shipment exactly as the wire carries it.
///
/// This class exists so that the domain does not have to. `Shipment` knows
/// nothing about `snake_case`, about the fact that a status arrives as a
/// discriminated object, or that the server sends timestamps as ISO-8601
/// strings — and it must not, because the day the API changes any of those,
/// the change has to stop at this file.
///
/// Every field is nullable and untyped-ish on purpose. What arrives is what
/// the far side chose to send, not what this app hoped for; the mapper is
/// where an absent field becomes a named failure instead of a `TypeError`
/// thrown two layers up.
@JsonSerializable()
class ShipmentDto {
  /// Creates the DTO.
  const ShipmentDto({
    this.id,
    this.barcode,
    this.status,
    this.consignee,
    this.history,
  });

  /// Reads one from decoded JSON.
  factory ShipmentDto.fromJson(Map<String, dynamic> json) =>
      _$ShipmentDtoFromJson(json);

  /// The shipment's identifier.
  final String? id;

  /// The number on the label.
  final String? barcode;

  /// Where it is, as a discriminated object.
  final ShipmentStatusDto? status;

  /// Who receives it.
  final ConsigneeDto? consignee;

  /// Every move it has made.
  final List<StatusTransitionDto>? history;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ShipmentDtoToJson(this);
}

/// A shipment status on the wire: a discriminator plus whatever that case
/// carries.
///
/// One flat object rather than a nested union, because that is what the API
/// sends. The mapper turns it into the `sealed ShipmentStatus` the domain
/// uses, and the fact that four of these five fields are null in any given
/// message is exactly the shape a domain type must never have.
@JsonSerializable()
class ShipmentStatusDto {
  /// Creates the DTO.
  const ShipmentStatusDto({
    this.kind,
    this.courier,
    this.proofReference,
    this.reason,
    this.at,
  });

  /// Reads one from decoded JSON.
  factory ShipmentStatusDto.fromJson(Map<String, dynamic> json) =>
      _$ShipmentStatusDtoFromJson(json);

  /// Which state, as the API names it.
  final String? kind;

  /// The courier, where the state has one.
  final String? courier;

  /// The proof reference, on a delivered shipment.
  final String? proofReference;

  /// The reason, on an undelivered one.
  final String? reason;

  /// When the state was reached, ISO-8601.
  final String? at;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ShipmentStatusDtoToJson(this);
}

/// A consignee on the wire.
@JsonSerializable()
class ConsigneeDto {
  /// Creates the DTO.
  const ConsigneeDto({this.name, this.phone, this.address});

  /// Reads one from decoded JSON.
  factory ConsigneeDto.fromJson(Map<String, dynamic> json) =>
      _$ConsigneeDtoFromJson(json);

  /// The name on the label.
  final String? name;

  /// A number to call on arrival.
  final String? phone;

  /// Where it is going.
  final AddressDto? address;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ConsigneeDtoToJson(this);
}

/// An address on the wire.
@JsonSerializable()
class AddressDto {
  /// Creates the DTO.
  const AddressDto({this.formatted, this.latitude, this.longitude});

  /// Reads one from decoded JSON.
  factory AddressDto.fromJson(Map<String, dynamic> json) =>
      _$AddressDtoFromJson(json);

  /// The address as it would be written on the label.
  final String? formatted;

  /// Degrees north.
  final double? latitude;

  /// Degrees east.
  final double? longitude;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$AddressDtoToJson(this);
}

/// One recorded move, on the wire.
@JsonSerializable()
class StatusTransitionDto {
  /// Creates the DTO.
  const StatusTransitionDto({this.from, this.to, this.at, this.by});

  /// Reads one from decoded JSON.
  factory StatusTransitionDto.fromJson(Map<String, dynamic> json) =>
      _$StatusTransitionDtoFromJson(json);

  /// The state left, as a discriminated object.
  final ShipmentStatusDto? from;

  /// The state entered.
  final ShipmentStatusDto? to;

  /// When, ISO-8601.
  final String? at;

  /// Who, where a person did it.
  final String? by;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$StatusTransitionDtoToJson(this);
}

/// A manifest row on the wire.
@JsonSerializable()
class ShipmentSummaryDto {
  /// Creates the DTO.
  const ShipmentSummaryDto({
    this.id,
    this.barcode,
    this.status,
    this.consigneeName,
    this.address,
  });

  /// Reads one from decoded JSON.
  factory ShipmentSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ShipmentSummaryDtoFromJson(json);

  /// The shipment's identifier.
  final String? id;

  /// The number on the label.
  final String? barcode;

  /// Where it is.
  final ShipmentStatusDto? status;

  /// Who receives it.
  final String? consigneeName;

  /// Where it is going.
  final String? address;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ShipmentSummaryDtoToJson(this);
}
