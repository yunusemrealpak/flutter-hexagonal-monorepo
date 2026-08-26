import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'attempt_reads.dart';
import 'complete_with_proof.dart';
import 'fail_with_reason.dart';
import 'start_attempt.dart';

/// The driving port's implementation: one intention per method, each of them a
/// call into a use case.
///
/// Deliberately thin, like every coordinator in this workspace. Everything
/// that decides anything is behind it — the policy in `ProofPolicy`, the
/// settle-once guard in `DeliveryAttempt`, the geofence rule in
/// `StartAttempt`. What this class adds is the shape of the port and the
/// change stream.
///
/// It is not called `DeliveryFacadeImpl`. The name says what it does rather
/// than which interface it satisfies.
final class DeliveryCoordinator implements DeliveryFacade {
  /// Creates the coordinator over its use cases.
  DeliveryCoordinator({
    required this._startAttempt,
    required this._complete,
    required this._fail,
    required this._reads,
  });

  final StartAttempt _startAttempt;
  final CompleteWithProof _complete;
  final FailWithReason _fail;
  final AttemptReads _reads;

  final StreamController<DeliveryAttempt> _changes =
      StreamController<DeliveryAttempt>.broadcast();

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> startAttempt({
    required ShipmentId shipment,
    required ActorId courier,
    DeliveryGrade grade = DeliveryGrade.standard,
  }) => _announce(
    _startAttempt((shipment: shipment, courier: courier, grade: grade)),
  );

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> completeWithProof({
    required DeliveryAttempt attempt,
    required ProofOfDelivery proof,
  }) => _announce(_complete((attempt: attempt, proof: proof)));

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> failWithReason({
    required DeliveryAttempt attempt,
    required NonDeliveryReason reason,
  }) => _announce(_fail((attempt: attempt, reason: reason)));

  @override
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    ShipmentId shipment,
  ) => _reads(shipment);

  /// Emits an attempt whenever one is opened or settled.
  ///
  /// A broadcast stream, so a stop list and a proof screen can both listen.
  /// Nothing is emitted for a refused call: the record did not change, and a
  /// screen that redrew on it would flicker for no reason.
  @override
  Stream<DeliveryAttempt> changes() => _changes.stream;

  /// Releases the change stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// coordinator owns the controller, so it is the only thing that can.
  Future<void> dispose() => _changes.close();

  Future<Result<DeliveryAttempt, DeliveryFailure>> _announce(
    Future<Result<DeliveryAttempt, DeliveryFailure>> work,
  ) async {
    final result = await work;
    if (result case Success(value: final attempt)) _changes.add(attempt);
    return result;
  }
}
