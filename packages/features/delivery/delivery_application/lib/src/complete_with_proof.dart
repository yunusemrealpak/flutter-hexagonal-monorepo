import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:sync_api/sync_api.dart';

import 'complete_delivery_command.dart';

/// What a caller wants closed, and with what.
typedef CompleteRequest = ({DeliveryAttempt attempt, ProofOfDelivery proof});

/// Closes an attempt with the evidence a courier captured.
///
/// Five steps, and the order is the design:
///
/// 1. **Check the policy.** Before anything is compressed or written. The
///    entity will check again when it settles — an entity that trusts its
///    caller guards nothing — but doing it first means a high-value parcel
///    closed without a photograph never costs a store write.
/// 2. **Compress the photograph.** Through a port, against a limit the
///    composition root supplied, because what fits depends on what will carry
///    it. A photograph that cannot be made to fit fails here rather than
///    sitting in an outbox on a device with no signal.
/// 3. **Store the evidence**, and keep the handle. The bytes stop here: the
///    queue, the event and the server all see a short string.
/// 4. **Queue the write.** Not send it. A courier who has just handed over a
///    parcel is not made to wait for a server, which is the whole reason
///    `sync` exists.
/// 5. **Publish `DeliveryCompleted`** — and only after the queue accepted the
///    write. A subscriber that closed a cash collection for a delivery which
///    was never durably recorded would be reacting to something that did not
///    happen.
///
/// The conflict policy is the default, `lastWriteWins`, and it is a decision
/// rather than an omission. If the office marked this parcel undeliverable
/// while the courier was in a basement, the courier is the one who was at the
/// door. Nothing is destroyed by preferring their record: the evidence itself
/// sits under its own reference either way.
final class CompleteWithProof
    implements
        UseCase<CompleteRequest, Result<DeliveryAttempt, DeliveryFailure>> {
  /// Creates the use case.
  ///
  /// [photoLimitBytes] is what a queued photograph may weigh. It arrives from
  /// the composition root because that is what knows which transport was
  /// bound; a limit compiled into this package would be wrong for one of the
  /// three apps.
  const CompleteWithProof({
    required this._store,
    required this._compressor,
    required this._sync,
    required this._events,
    required this._clock,
    this.photoLimitBytes = 512 * 1024,
  });

  final ProofStorePort _store;
  final MediaCompressorPort _compressor;
  final SyncFacade _sync;
  final DomainEventBus _events;
  final Clock _clock;

  /// The largest photograph this app is prepared to queue.
  final int photoLimitBytes;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> call(
    CompleteRequest request,
  ) async {
    final attempt = request.attempt;
    if (attempt.isSettled) {
      return Failed(AttemptAlreadySettled(attempt.id.value));
    }

    final policy = ProofPolicy.forGrade(attempt.grade);
    if (policy.accept(request.proof) case Failed(:final failure)) {
      return Failed(failure);
    }

    final ProofOfDelivery proof;
    switch (await _shrink(request.proof)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        proof = value;
    }

    final ProofReference reference;
    switch (await _store.put(proof)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        reference = value;
    }

    final DeliveryAttempt settled;
    switch (attempt.completeWith(
      proof: proof,
      reference: reference,
      at: _clock.now(),
    )) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        settled = value;
    }

    final queued = await _sync.enqueue(CompleteDeliveryCommand(settled));
    if (queued case Failed(:final failure)) {
      // The queue is the durable record. Reporting success here would tell a
      // courier their afternoon is safe when the only copy of it is in memory.
      return Failed(DeliveryUnavailable(detail: '$failure'));
    }

    _events.publish(
      DeliveryCompleted(
        shipment: settled.shipment,
        courier: settled.courier,
        proofReference: reference.value,
        // Domain time: when the hand-over happened, not when a subscriber
        // heard about it. The two are hours apart when a queue drains late.
        occurredAt: settled.settledAt ?? _clock.now(),
      ),
    );

    return Success(settled);
  }

  /// Returns [proof] with its photograph brought under the limit.
  ///
  /// A proof with no photograph is returned untouched rather than sent through
  /// a compressor that has nothing to do.
  Future<Result<ProofOfDelivery, DeliveryFailure>> _shrink(
    ProofOfDelivery proof,
  ) async {
    final photo = proof.photo;
    if (photo == null) return Success(proof);

    return (await _compressor.compress(
      photo,
      limitBytes: photoLimitBytes,
    )).map(proof.withPhoto);
  }
}
