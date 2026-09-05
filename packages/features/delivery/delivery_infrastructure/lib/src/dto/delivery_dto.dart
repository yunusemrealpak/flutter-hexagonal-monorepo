import 'package:json_annotation/json_annotation.dart';

part 'delivery_dto.g.dart';

/// A proof exactly as the wire and the device's store carry it.
///
/// One DTO serving two boundaries, which is a decision rather than an
/// accident: what `RemoteProofStore` posts and what `LocalEncryptedProofStore`
/// writes to disk describe the same thing, and two shapes would drift apart
/// the first time a field was added to one of them.
///
/// Flat rather than nested, with one group of fields per kind of evidence.
/// Nesting three optional objects would read better and would mean three more
/// DTOs to keep nullable, three more `explicit_to_json` corners, and a mapper
/// that walks a tree to find out that nothing was captured.
///
/// Every field is nullable on purpose. What arrives is what the far side chose
/// to send — or what an older release of this app wrote to disk — and the
/// mapper is where an absent field becomes a named failure instead of a
/// `TypeError` thrown two layers up.
///
/// The bytes travel base64-encoded, because JSON has no other way to carry
/// them. That is also the reason `CompleteDeliveryCommand` puts a *reference*
/// in the outbox rather than a proof: base64 is a third larger than the bytes
/// it encodes, and an outbox row is a `TEXT` column on a courier's phone.
@JsonSerializable()
class ProofDto {
  /// Creates the DTO.
  const ProofDto({
    this.recipientName,
    this.recipientRelationship,
    this.capturedAt,
    this.signatureBase64,
    this.signatureCapturedAt,
    this.photoBase64,
    this.photoMimeType,
    this.photoCapturedAt,
    this.scanSymbol,
    this.scanAt,
  });

  /// Reads one from decoded JSON.
  factory ProofDto.fromJson(Map<String, dynamic> json) =>
      _$ProofDtoFromJson(json);

  /// What the person at the door gave as their name.
  final String? recipientName;

  /// What they are to the consignee.
  final String? recipientRelationship;

  /// When the hand-over was recorded, ISO-8601.
  final String? capturedAt;

  /// The signature image, base64.
  final String? signatureBase64;

  /// When it was drawn, ISO-8601.
  final String? signatureCapturedAt;

  /// The photograph, base64.
  final String? photoBase64;

  /// What kind of image it is.
  final String? photoMimeType;

  /// When the shutter went, ISO-8601.
  final String? photoCapturedAt;

  /// What the scanner read.
  final String? scanSymbol;

  /// When, ISO-8601.
  final String? scanAt;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ProofDtoToJson(this);
}

/// One visit, as the operation's record of it crosses the wire.
///
/// [outcome] is a tag rather than a shape, and the proof and the reason are
/// siblings rather than alternatives. The domain's `AttemptOutcome` is a union
/// and this is not, because a DTO's job is to survive contact with whatever
/// the far side actually sent — including a `completed` with no proof, which
/// the mapper turns into a named failure rather than into a shrug.
@JsonSerializable(explicitToJson: true)
class DeliveryAttemptDto {
  /// Creates the DTO.
  const DeliveryAttemptDto({
    this.id,
    this.shipmentId,
    this.courierId,
    this.grade,
    this.startedAt,
    this.settledAt,
    this.outcome,
    this.proofReference,
    this.proof,
    this.reason,
    this.reasonNote,
    this.reasonRequestedFor,
  });

  /// Reads one from decoded JSON.
  factory DeliveryAttemptDto.fromJson(Map<String, dynamic> json) =>
      _$DeliveryAttemptDtoFromJson(json);

  /// The attempt's identifier — what a server de-duplicates on.
  final String? id;

  /// Which parcel.
  final String? shipmentId;

  /// Who was at the door.
  final String? courierId;

  /// How much proof it was worth: `standard` or `highValue`.
  final String? grade;

  /// When the courier arrived, ISO-8601.
  final String? startedAt;

  /// When the visit ended, ISO-8601, or absent while it has not.
  final String? settledAt;

  /// `inProgress`, `completed` or `failed`.
  final String? outcome;

  /// Where the evidence is, on a completed attempt.
  final String? proofReference;

  /// The evidence itself, where the far side chose to include it.
  final ProofDto? proof;

  /// Why it did not happen, on a failed attempt.
  final String? reason;

  /// What the courier wrote about it.
  final String? reasonNote;

  /// The day the recipient asked for, ISO-8601.
  final String? reasonRequestedFor;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$DeliveryAttemptDtoToJson(this);
}

/// Where a parcel is going, and how close counts as being there.
///
/// The answer to *"where should the courier be"* comes from delivery's own
/// service rather than from `shipments`, and that is section 2 rather than a
/// preference: this package may not depend on a foreign `_api` at all. The
/// operation publishes the point on delivery's endpoint; what shipments calls
/// it is shipments' business.
@JsonSerializable()
class GeoTargetDto {
  /// Creates the DTO.
  const GeoTargetDto({this.latitude, this.longitude, this.allowedMetres});

  /// Reads one from decoded JSON.
  factory GeoTargetDto.fromJson(Map<String, dynamic> json) =>
      _$GeoTargetDtoFromJson(json);

  /// Degrees north.
  final double? latitude;

  /// Degrees east.
  final double? longitude;

  /// How far from it the operation is prepared to accept a delivery.
  ///
  /// Sent by the server rather than compiled in, because a dense city and a
  /// rural round want different numbers and neither is a fact about this app.
  final double? allowedMetres;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$GeoTargetDtoToJson(this);
}

/// What a proof store answers with when it has stored something.
@JsonSerializable()
class ProofReferenceDto {
  /// Creates the DTO.
  const ProofReferenceDto({this.reference});

  /// Reads one from decoded JSON.
  factory ProofReferenceDto.fromJson(Map<String, dynamic> json) =>
      _$ProofReferenceDtoFromJson(json);

  /// The handle the stored evidence can be found by.
  final String? reference;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$ProofReferenceDtoToJson(this);
}
