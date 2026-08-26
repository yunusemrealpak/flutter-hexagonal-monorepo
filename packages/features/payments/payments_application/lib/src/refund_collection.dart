import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';

import 'settlement_updates.dart';

/// Gives money back.
///
/// The gateway is the record of truth and the refund goes through it, which is
/// also where the idempotency lives: a courier whose refund request timed out
/// sends it again, and giving the money back twice is the same loss as taking
/// it twice.
///
/// **Cash comes out of the drawer only after the gateway agreed.** The other
/// order would leave a courier short by the amount of any refund the operation
/// then refused, and they are the one holding the notes.
///
/// There is no offline path here, and the asymmetry with `CollectOnDelivery`
/// is deliberate. Cash may be *taken* offline because the money is already in
/// the courier's hand and the server is only being told; it may not be *given
/// back* offline, because handing over notes against a record nobody has
/// confirmed is how an operation loses money to a customer who asks twice.
final class RefundCollection
    implements
        UseCase<IdempotencyKey, Result<PaymentAttempt, PaymentsFailure>> {
  /// Creates the use case.
  const RefundCollection({
    required this._gateway,
    required this._drawer,
    required this._settlements,
    required this._clock,
    required this._logger,
  });

  final PaymentsGateway _gateway;
  final CashDrawerPort _drawer;
  final SettlementStore _settlements;
  final Clock _clock;
  final Logger _logger;

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> call(
    IdempotencyKey key,
  ) async {
    final PaymentAttempt refunded;
    switch (await _gateway.refund(key.value)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        refunded = value;
    }

    if (refunded.request.method.isCash) {
      final released = await _drawer.release(refunded.amount);
      if (released case Failed(:final failure)) {
        // The refund is recorded and the notes are the courier's problem to
        // reconcile. Reporting a failure here would leave the caller thinking
        // the money was not given back when the operation says it was.
        _logger.error(
          'the refund is recorded; the drawer could not be reduced',
          context: {'failure': '$failure', 'key': key.value},
        );
      }
    }

    final updated = await SettlementUpdates.include(
      refunded,
      store: _settlements,
      at: _clock.now(),
    );
    if (updated case Failed(:final failure)) {
      _logger.warning(
        "the refund stands; the day's total was not updated",
        context: {'failure': '$failure'},
      );
    }

    return Success(refunded);
  }
}
