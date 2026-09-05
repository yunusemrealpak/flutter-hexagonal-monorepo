import 'package:freezed_annotation/freezed_annotation.dart';

import 'shipment_status.dart';

part 'shipment_summary.freezed.dart';

/// A shipment as a list shows it: enough to render a row, and no more.
///
/// A read model, not a shrunken entity. The dispatcher's table renders
/// thousands of these and needs none of the history, and the courier's stop
/// list needs the consignee's name without the phone number. Returning
/// `Shipment` instead would make every list pay for the full aggregate and
/// would put the decision about what a row shows in whichever adapter built
/// it.
///
/// Generated: no identity of its own — two summaries with the same contents
/// are the same row — nothing to validate, nothing secret.
@freezed
abstract class ShipmentSummary with _$ShipmentSummary {
  /// Describes one row of a shipment list.
  const factory ShipmentSummary({
    /// The identifier, as a plain string.
    ///
    /// Not a `ShipmentId`: a summary is what a list renders, and re-parsing
    /// eleven hundred identifiers to draw a screen buys nothing. The caller
    /// that acts on a row parses it once, at the point of acting.
    required String id,

    /// The number on the label.
    required String barcode,

    /// Where the shipment is.
    required ShipmentStatus status,

    /// Who receives it.
    required String consigneeName,

    /// Where it is going, as it would be written on the label.
    required String address,
  }) = _ShipmentSummary;

  const ShipmentSummary._();
}
