import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:identity_api/identity_api.dart';

import 'shipment_id.dart';
import 'shipment_status.dart';

part 'shipment_failure.freezed.dart';

/// Everything that can go wrong on a shipments port, or inside the shipment
/// state machine.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
@freezed
sealed class ShipmentFailure extends Failure with _$ShipmentFailure {
  const ShipmentFailure._();

  /// The move that was asked for is not one the state machine allows.
  ///
  /// The single most important case in this package. It is returned by
  /// `Shipment`, not by a use case and not by an adapter, which is what makes
  /// "a shipment cannot be delivered before it is loaded" a property of the
  /// domain rather than of whichever caller remembered to check.
  ///
  /// Both labels are carried, because "invalid transition" on its own is the
  /// kind of message that sends somebody to a debugger to find out which one.
  const factory ShipmentFailure.invalidTransition({
    required String from,
    required String to,
  }) = InvalidTransition;

  /// A transition was attempted by a courier the shipment is not on.
  ///
  /// Distinct from [InvalidTransition]: the move itself is legal, and the
  /// person asking for it is the problem. Collapsing the two would report a
  /// mis-scan at the wrong van as a broken state machine.
  const factory ShipmentFailure.notTheAssignedCourier({
    required ActorId assigned,
    required ActorId attempted,
  }) = NotTheAssignedCourier;

  /// Nothing is stored under this identifier.
  const factory ShipmentFailure.shipmentNotFound(ShipmentId id) =
      ShipmentNotFound;

  /// The identifier could not be read.
  const factory ShipmentFailure.malformedShipmentId(String raw) =
      MalformedShipmentId;

  /// The barcode could not be read.
  ///
  /// [reason] names which of the two checks failed — shape or check digit —
  /// because a scanner that returns eleven digits and a scanner that returns
  /// twelve wrong ones are different faults with different fixes.
  const factory ShipmentFailure.malformedBarcode({
    required String raw,
    required String reason,
  }) = MalformedBarcode;

  /// The barcode is well formed and matches no shipment in this operation.
  const factory ShipmentFailure.barcodeNotRecognised(String barcode) =
      BarcodeNotRecognised;

  /// A value object refused the input it was given.
  const factory ShipmentFailure.malformedValue({
    required String field,
    required String reason,
  }) = MalformedValue;

  /// The store or the remote end could not be reached, so nothing is known
  /// either way.
  const factory ShipmentFailure.shipmentsUnavailable({String? detail}) =
      ShipmentsUnavailable;
}

/// Builds an [InvalidTransition] from the two states involved.
///
/// An extension rather than a second factory, so that the union keeps one
/// constructor per case and the convenience does not become a case somebody
/// pattern-matches on by mistake.
extension InvalidTransitionFrom on ShipmentStatus {
  /// The failure for refusing a move from this state to [target].
  ShipmentFailure cannotBecome(ShipmentStatus target) =>
      InvalidTransition(from: label, to: target.label);
}
