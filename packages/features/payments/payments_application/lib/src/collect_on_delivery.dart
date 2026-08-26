import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:sync_api/sync_api.dart';

import 'collect_payment_command.dart';
import 'settlement_updates.dart';

/// What a caller wants collected.
typedef CollectRequest = ({
  ShipmentId shipment,
  ActorId courier,
  Money amount,
  PaymentMethod method,
});

/// Takes money at a door, once, whatever the connection is doing.
///
/// **The idempotency key is minted here and bound to the intention, not to the
/// call.** Before anything else, the use case asks the gateway whether it
/// already has an attempt against this parcel. If it does and the money has
/// moved, that is the answer — the courier tapped twice, and the second tap
/// costs nothing. If it does and the money has not moved, its key is reused,
/// so a retry after a refusal is the same intention rather than a second one.
/// Only when there is nothing does a key come from `IdGenerator`.
///
/// That is what the specification means by binding the key to *one payment
/// intention*: a use case that minted on every call would produce a new key
/// per tap, and the far side would have no way to tell a retry from a second
/// charge.
///
/// **Cash may be recorded offline; a card may not.** The two look alike and
/// are not. Cash at a door needs no authorisation — the money is already in
/// the courier's hand, and the server is being told about it — so an
/// unreachable gateway means the write goes to the outbox and the collection
/// stands. A card needs an acquirer to say yes, and reporting success without
/// one would be inventing money. That distinction is a *business* rule, which
/// is why it lives here and not in an adapter that could only see a timeout.
///
/// **A receipt that will not print does not undo a collection.** Money the
/// courier is holding with no record of it is worse than a customer with no
/// slip of paper, so the failure is logged and the collection stands. The same
/// applies to a settlement that could not be updated: the money is recorded,
/// and the day's total can be rebuilt from the attempts.
final class CollectOnDelivery
    implements
        UseCase<CollectRequest, Result<PaymentAttempt, PaymentsFailure>> {
  /// Creates the use case.
  const CollectOnDelivery({
    required this._gateway,
    required this._drawer,
    required this._receipts,
    required this._settlements,
    required this._sync,
    required this._clock,
    required this._ids,
    required this._logger,
  });

  final PaymentsGateway _gateway;
  final CashDrawerPort _drawer;
  final ReceiptPrinterPort _receipts;
  final SettlementStore _settlements;
  final SyncFacade _sync;
  final Clock _clock;
  final IdGenerator _ids;
  final Logger _logger;

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> call(
    CollectRequest request,
  ) async {
    final isCash = request.method.isCash;

    // What the server already knows. Offline this fails, and for cash that is
    // survivable: the courier is standing there with the money.
    PaymentAttempt? existing;
    switch (await _gateway.attemptFor(request.shipment.value)) {
      case Failed(:final failure):
        if (!isCash) return Failed(failure);
        _logger.debug(
          'collecting cash against an unreachable gateway',
          context: {'failure': '$failure'},
        );
      case Success(:final value):
        existing = value;
    }

    if (existing != null && !existing.isOutstanding) {
      // The courier tapped twice, or a retry arrived after the first copy
      // landed. The answer is what happened the first time.
      return Success(existing);
    }

    final IdempotencyKey key;
    switch (_keyFor(existing)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        key = value;
    }

    if (isCash) {
      final accepted = await _drawer.accept(request.amount);
      if (accepted case Failed(:final failure)) return Failed(failure);
    }

    final PaymentAttempt taken;
    switch (PaymentAttempt.intending(
      key: key,
      request: CollectionRequest(
        shipment: request.shipment,
        courier: request.courier,
        amount: request.amount,
        method: request.method,
      ),
    ).taken(at: _clock.now())) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        taken = value;
    }

    final PaymentAttempt recorded;
    switch (await _record(taken, isCash: isCash)) {
      case Failed(:final failure):
        if (isCash) await _giveBack(request.amount);
        return Failed(failure);
      case Success(:final value):
        recorded = value;
    }

    await _issueReceipt(recorded);
    await _addToTheDay(recorded);

    return Success(recorded);
  }

  /// Records the attempt, falling back to the outbox for cash.
  Future<Result<PaymentAttempt, PaymentsFailure>> _record(
    PaymentAttempt taken, {
    required bool isCash,
  }) async {
    final collected = await _gateway.collect(taken);
    if (collected case Success()) return collected;

    final failure =
        (collected as Failed<PaymentAttempt, PaymentsFailure>).failure;

    // A refusal is an answer, not a connection problem. Queueing it would tell
    // a courier the money was taken when an acquirer had just said no.
    if (failure is CollectionRefused) return Failed(failure);
    if (!isCash) return Failed(failure);

    final queued = await _sync.enqueue(
      CollectPaymentCommand(taken),
      // The one place in the workspace that asks for a person. Two records of
      // the same cash collection are either a double charge or a lost one, and
      // neither is something a queue may decide on its own.
      policy: const ConflictPolicy.manualReview(),
    );
    if (queued case Failed(failure: final queueFailure)) {
      return Failed(PaymentsUnavailable(detail: '$queueFailure'));
    }

    _logger.info(
      'cash collection queued for a gateway that could not be reached',
      context: {'key': taken.id.value},
    );
    return Success(taken);
  }

  Result<IdempotencyKey, PaymentsFailure> _keyFor(PaymentAttempt? existing) =>
      existing == null
      ? IdempotencyKey.parse(_ids.newId())
      : Success(existing.id);

  Future<void> _giveBack(Money amount) async {
    final released = await _drawer.release(amount);
    if (released case Failed(:final failure)) {
      _logger.error(
        'cash was accepted for a collection that was refused, and could not '
        'be released',
        context: {'failure': '$failure'},
      );
    }
  }

  Future<void> _issueReceipt(PaymentAttempt attempt) async {
    final issued = await _receipts.issue(attempt);
    if (issued case Failed(:final failure)) {
      _logger.warning(
        'the collection stands; the receipt did not print',
        context: {'failure': '$failure'},
      );
    }
  }

  Future<void> _addToTheDay(PaymentAttempt attempt) async {
    final updated = await SettlementUpdates.include(
      attempt,
      store: _settlements,
      at: _clock.now(),
    );
    if (updated case Failed(:final failure)) {
      _logger.warning(
        "the collection stands; the day's total was not updated",
        context: {'failure': '$failure'},
      );
    }
  }
}
