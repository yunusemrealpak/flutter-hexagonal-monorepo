import 'package:json_annotation/json_annotation.dart';

part 'payments_dto.g.dart';

/// One attempt to move money, as the wire and the device's copy carry it.
///
/// One DTO serving two boundaries, which is a decision rather than an
/// accident: what `RestPaymentsGateway` posts and what
/// `DeviceBackedPaymentsGateway` keeps on the phone describe the same thing,
/// and two shapes would drift apart the first time a field was added to one.
///
/// **The amount is an integer of minor units and a currency code, never a
/// decimal.** A JSON number is a double in most parsers, and a settlement
/// rebuilt from doubles is off by an amount somebody has to explain. This is
/// the boundary where that mistake is usually made.
///
/// Every field is nullable on purpose. What arrives is what the far side chose
/// to send — or what an older release wrote to disk — and the mapper is where
/// an absent field becomes a named failure instead of a `TypeError` two layers
/// up.
@JsonSerializable()
class PaymentAttemptDto {
  /// Creates the DTO.
  const PaymentAttemptDto({
    this.idempotencyKey,
    this.shipmentId,
    this.courierId,
    this.minorUnits,
    this.currency,
    this.method,
    this.last4,
    this.transferReference,
    this.outcome,
    this.takenAt,
    this.refundedAt,
    this.refusalReason,
  });

  /// Reads one from decoded JSON.
  factory PaymentAttemptDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentAttemptDtoFromJson(json);

  /// The key the server de-duplicates on.
  final String? idempotencyKey;

  /// Which parcel the money is owed against.
  final String? shipmentId;

  /// Who collected it.
  final String? courierId;

  /// How much, in the currency's smallest unit.
  final int? minorUnits;

  /// The ISO 4217 code.
  final String? currency;

  /// `cash`, `card` or `transfer`.
  final String? method;

  /// The last four digits, on a card.
  ///
  /// The only part of a card that ever crosses this boundary. A payments
  /// feature that carried a full number would put every system that reads this
  /// JSON inside a compliance scope nobody signed up for.
  final String? last4;

  /// Somebody else's reference, on a transfer.
  final String? transferReference;

  /// `pending`, `taken`, `refused` or `refunded`.
  final String? outcome;

  /// When the money changed hands, ISO-8601.
  final String? takenAt;

  /// When it was given back, ISO-8601.
  final String? refundedAt;

  /// What the far side said when it refused.
  final String? refusalReason;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$PaymentAttemptDtoToJson(this);
}

/// One courier's day, as a store keeps it.
///
/// The totals are stored rather than derived, and `Settlement.restored` is the
/// factory that reads them back. Recomputing them here would mean holding
/// every attempt of the day, which is what storing a total was for.
@JsonSerializable()
class SettlementDto {
  /// Creates the DTO.
  const SettlementDto({
    this.id,
    this.courierId,
    this.day,
    this.currency,
    this.collectedMinorUnits,
    this.refundedMinorUnits,
    this.closedAt,
  });

  /// Reads one from decoded JSON.
  factory SettlementDto.fromJson(Map<String, dynamic> json) =>
      _$SettlementDtoFromJson(json);

  /// The identifier, derived from the courier and the date.
  final String? id;

  /// Whose day it is.
  final String? courierId;

  /// Which day, ISO-8601.
  final String? day;

  /// The ISO 4217 code both totals are in.
  final String? currency;

  /// The cash taken, in minor units.
  final int? collectedMinorUnits;

  /// The cash given back, in minor units.
  final int? refundedMinorUnits;

  /// When the day was handed in, ISO-8601, or absent while it is open.
  final String? closedAt;

  /// Writes it back to JSON.
  Map<String, dynamic> toJson() => _$SettlementDtoToJson(this);
}
