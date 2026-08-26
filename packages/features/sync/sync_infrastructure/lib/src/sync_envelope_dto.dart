import 'package:json_annotation/json_annotation.dart';

part 'sync_envelope_dto.g.dart';

/// An attempt exactly as the wire carries it.
///
/// This class exists so that `SyncEnvelope` does not have to. The domain type
/// knows nothing about `snake_case`, about the fact that the policy travels as
/// a string, or that timestamps go out as ISO-8601 — and it must not, because
/// the day the API changes any of those the change has to stop at this file.
///
/// [payload] is a `String` here, and stays one all the way down. It is the
/// feature's own serialised body, and re-encoding it as a nested object would
/// mean `sync` decoding something it is not entitled to read.
@JsonSerializable()
class SyncEnvelopeDto {
  /// Creates the DTO.
  const SyncEnvelopeDto({
    required this.id,
    required this.type,
    required this.payload,
    required this.policy,
    required this.queuedAt,
    required this.attempt,
    required this.cursor,
  });

  /// Reads one from decoded JSON.
  factory SyncEnvelopeDto.fromJson(Map<String, dynamic> json) =>
      _$SyncEnvelopeDtoFromJson(json);

  /// The entry identifier, which is also the idempotency handle.
  final String id;

  /// The routing key the feature declared.
  final String type;

  /// The feature's body, still opaque.
  final String payload;

  /// The conflict policy, as a string.
  final String policy;

  /// When the work happened, ISO-8601, in the server's frame of reference.
  final String queuedAt;

  /// Which attempt this is, counting from 1.
  final int attempt;

  /// Where this device believes the server is.
  final String cursor;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SyncEnvelopeDtoToJson(this);
}

/// What the server sends back when it accepts an envelope.
///
/// Every field is nullable, which is the shape a DTO that arrives from a
/// network has: what turns up is what the far side chose to send, not what
/// this app hoped for. The mapper is where an absent field becomes a named
/// failure instead of a `TypeError` thrown two layers up.
@JsonSerializable()
class SyncAckDto {
  /// Creates the DTO.
  const SyncAckDto({this.cursor, this.conflict, this.reason});

  /// Reads one from decoded JSON.
  factory SyncAckDto.fromJson(Map<String, dynamic> json) =>
      _$SyncAckDtoFromJson(json);

  /// The server's position after this envelope.
  final String? cursor;

  /// Set when the server refused because it has moved on.
  ///
  /// A 2xx body can carry this: an API that answers "accepted, but you were
  /// working against an old position" with a success status is not unusual,
  /// and the adapter has to notice it rather than treating the response as a
  /// clean acceptance.
  final bool? conflict;

  /// Why, in the server's words.
  final String? reason;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SyncAckDtoToJson(this);
}

/// The server's own clock, as the wire carries it.
@JsonSerializable()
class ServerTimeDto {
  /// Creates the DTO.
  const ServerTimeDto({this.now});

  /// Reads one from decoded JSON.
  factory ServerTimeDto.fromJson(Map<String, dynamic> json) =>
      _$ServerTimeDtoFromJson(json);

  /// The server's current instant, ISO-8601.
  final String? now;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ServerTimeDtoToJson(this);
}
