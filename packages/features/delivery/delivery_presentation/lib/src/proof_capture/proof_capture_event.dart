import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// What can happen to the proof screen.
///
/// Sealed, so the bloc's handlers are exhaustive over the things a courier can
/// do at a door.
sealed class ProofCaptureEvent {
  const ProofCaptureEvent();
}

/// The courier is at the address; open an attempt.
///
/// Carries the parcel rather than the bloc holding it, because the same bloc
/// answers the retry on the failure view and a retry is this event again.
final class ArrivalRequested extends ProofCaptureEvent {
  /// Creates the event for [shipment].
  const ArrivalRequested({
    required this.shipment,
    this.grade = DeliveryGrade.standard,
  });

  /// Which parcel this visit is about.
  final ShipmentId shipment;

  /// How much proof it is worth.
  final DeliveryGrade grade;
}

/// Somebody typed into the recipient field.
final class RecipientNamed extends ProofCaptureEvent {
  /// Creates the event.
  const RecipientNamed(this.name);

  /// What the field now holds.
  final String name;
}

/// What came back when this app was asked for a signature.
final class SignatureCaptured extends ProofCaptureEvent {
  /// Creates the event.
  const SignatureCaptured(this.capture);

  /// The evidence, or why there is none.
  final Result<SignatureCapture, CaptureRefusal> capture;
}

/// What came back when this app was asked for a photograph.
final class PhotoCaptured extends ProofCaptureEvent {
  /// Creates the event.
  const PhotoCaptured(this.capture);

  /// The evidence, or why there is none.
  final Result<PhotoEvidence, CaptureRefusal> capture;
}

/// A barcode was read at the door.
///
/// No refusal branch, and that is not an oversight: a scan is produced by a
/// screen this app already owns rather than by a device capability somebody
/// can decline.
final class ScanCaptured extends ProofCaptureEvent {
  /// Creates the event.
  const ScanCaptured(this.scan);

  /// What was read.
  final ScanEvidence scan;
}

/// A request to end the visit, one way or the other.
///
/// **Sealed with two subclasses so that one `on<SettlementRequested>` covers
/// both**, and that shared registration is the design rather than a shortcut.
/// A transformer is attached to one registration and does not span two, so
/// recording a hand-over and recording a failed visit under separate handlers
/// would leave a courier who taps *delivered* and then *could not deliver*
/// with two settlements in flight against the same attempt. They are one
/// window because they close the same door.
sealed class SettlementRequested extends ProofCaptureEvent {
  const SettlementRequested();
}

/// The parcel was handed over; close the attempt with the evidence.
final class HandoverRecorded extends SettlementRequested {
  /// Creates the event.
  const HandoverRecorded();
}

/// Nobody took the parcel; close the attempt with a reason.
final class NonDeliveryRecorded extends SettlementRequested {
  /// Creates the event.
  const NonDeliveryRecorded(this.reason);

  /// Why the visit ended without a hand-over.
  final NonDeliveryReason reason;
}
