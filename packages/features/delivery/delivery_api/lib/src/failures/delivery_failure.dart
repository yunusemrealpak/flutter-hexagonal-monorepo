import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_failure.freezed.dart';

/// Everything that can go wrong on a delivery port, or inside an attempt.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them.
///
/// Note what is *not* here: nothing in this union describes a delivery that
/// was attempted and did not happen. A recipient who was out is not a failure
/// of the software — it is the outcome of a visit, it is worth money to record
/// accurately, and it lives in `NonDeliveryReason` on the successful side of
/// the `Result`. Collapsing the two would make "nobody was home" and "the
/// proof store is locked" the same shape, and a courier's screen could not
/// tell a person which of the two had happened.
@freezed
sealed class DeliveryFailure extends Failure with _$DeliveryFailure {
  const DeliveryFailure._();

  /// A value object refused the input it was given.
  const factory DeliveryFailure.malformedValue({
    required String field,
    required String reason,
  }) = MalformedDeliveryValue;

  /// The proof does not meet what this shipment's grade insists on.
  ///
  /// Carries what is missing rather than a sentence, because the caller has to
  /// act on it: a courier's screen turns `['photo']` into an open camera, and
  /// a message saying "insufficient proof" turns into a shrug.
  const factory DeliveryFailure.proofInsufficient({
    required String grade,
    required List<String> missing,
  }) = ProofInsufficient;

  /// The attempt has already been completed or failed.
  ///
  /// The one that stops a double-tap becoming two deliveries. It is refused by
  /// the entity rather than by a use case, so the guard holds no matter which
  /// driving adapter asked.
  const factory DeliveryFailure.attemptAlreadySettled(String attempt) =
      AttemptAlreadySettled;

  /// The courier is not close enough to the address to be delivering.
  const factory DeliveryFailure.outsideDeliveryArea({
    required double metresAway,
    required double allowedMetres,
  }) = OutsideDeliveryArea;

  /// The device's position could not be read at all.
  ///
  /// Distinct from [OutsideDeliveryArea]: "I cannot see where you are" and
  /// "you are three streets away" call for different things from a courier,
  /// and an operation that treated them alike would either block deliveries in
  /// basements or accept them from the depot.
  const factory DeliveryFailure.positionUnavailable({String? detail}) =
      DeliveryPositionUnavailable;

  /// The device will not report its position, and only its settings page can
  /// change that.
  ///
  /// Distinct from [DeliveryPositionUnavailable] for the reason
  /// `location_service` keeps `LocationPermissionBlocked` apart from
  /// `LocationPermissionDenied` one layer down: the two lead a courier to
  /// different places. A fix that has not arrived is retried, and a permission
  /// the operating system has stopped asking about is not — prompting again
  /// shows nothing at all on iOS. A screen that could not tell them apart
  /// would offer a retry that can never work.
  ///
  /// It carries no detail. What a courier does about it is the same whichever
  /// operating system refused, and the string that would go here is the one
  /// `positionUnavailable` already carries for the log.
  const factory DeliveryFailure.positionBlocked() = DevicePositionBlocked;

  /// The evidence could not be written down.
  const factory DeliveryFailure.proofStoreUnavailable({String? detail}) =
      ProofStoreUnavailable;

  /// Nothing is stored under that reference.
  const factory DeliveryFailure.proofNotFound(String reference) = ProofNotFound;

  /// The photograph is too big to carry and could not be made smaller.
  const factory DeliveryFailure.mediaTooLarge({
    required int bytes,
    required int limit,
  }) = MediaTooLarge;

  /// The operation's record of its deliveries could not be reached.
  const factory DeliveryFailure.deliveryUnavailable({String? detail}) =
      DeliveryUnavailable;
}
