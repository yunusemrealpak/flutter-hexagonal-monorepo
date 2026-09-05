import 'package:json_annotation/json_annotation.dart';

part 'session_dto.g.dart';

/// A session exactly as the wire and the keychain carry it.
///
/// One DTO for both, deliberately. The token, the actor and the device binding
/// are the same three facts whether they arrive from a sign-in response or
/// come back out of storage, and a second near-identical shape would be a
/// second place to forget a field. What differs is only who produced it, and
/// the mapper checks both the same way.
@JsonSerializable()
class SessionDto {
  /// Creates the DTO.
  const SessionDto({
    this.actor,
    this.accessToken,
    this.expiresAt,
    this.refreshableUntil,
    this.device,
  });

  /// Reads one from decoded JSON.
  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  /// Who is signed in.
  final ActorDto? actor;

  /// The bearer token.
  final String? accessToken;

  /// When the token stops being accepted, ISO-8601.
  final String? expiresAt;

  /// When the session can no longer be refreshed, ISO-8601.
  final String? refreshableUntil;

  /// The device the session is tied to.
  final DeviceBindingDto? device;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);
}

/// An actor on the wire.
@JsonSerializable()
class ActorDto {
  /// Creates the DTO.
  const ActorDto({this.id, this.displayName, this.roles, this.grants});

  /// Reads one from decoded JSON.
  factory ActorDto.fromJson(Map<String, dynamic> json) =>
      _$ActorDtoFromJson(json);

  /// The account identifier.
  final String? id;

  /// How the actor is named in the interface.
  final String? displayName;

  /// The roles held, by name.
  final List<String>? roles;

  /// Permissions granted to this actor personally, by name.
  final List<String>? grants;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ActorDtoToJson(this);
}

/// A device binding on the wire.
@JsonSerializable()
class DeviceBindingDto {
  /// Creates the DTO.
  const DeviceBindingDto({this.deviceId, this.fingerprint, this.boundAt});

  /// Reads one from decoded JSON.
  factory DeviceBindingDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceBindingDtoFromJson(json);

  /// The installation's stable identifier.
  final String? deviceId;

  /// A digest of the characteristics the binding was issued against.
  final String? fingerprint;

  /// When it was issued, ISO-8601.
  final String? boundAt;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$DeviceBindingDtoToJson(this);
}
