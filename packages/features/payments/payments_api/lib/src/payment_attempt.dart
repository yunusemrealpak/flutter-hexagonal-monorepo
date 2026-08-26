import 'package:core_kernel/core_kernel.dart';

import 'collection_request.dart';
import 'idempotency_key.dart';
import 'money.dart';
import 'payment_outcome.dart';
import 'payments_failure.dart';

/// One intention to move money, and how far it has got.
///
/// **Its identifier is the idempotency key**, which is the whole design of
/// this feature in one line. Two attempts with the same key are the same
/// attempt — that is what `Entity` equality already means — so the double
/// charge is not a bug to guard against but a state the type system cannot
/// express. Giving the attempt an identifier of its own *beside* the key would
/// have made "two attempts, one key" and "one attempt, two keys" both
/// constructible, and one of those is somebody's money.
///
/// The rules live here rather than in a use case:
///
/// *Money moves once.* [taken] and [refunded] refuse an outcome that is
/// already final, which is what stops a retry of a successful collection
/// becoming a second one even if the key somehow reached the gateway twice.
///
/// *A refusal is not final.* A declined card can be tried again under the same
/// intention. Treating a refusal as settled would leave a courier unable to
/// take money the customer is holding out.
///
/// *Nothing is refunded that was not taken.* Giving back money that never
/// arrived is a hole in a settlement that nobody can close.
final class PaymentAttempt extends Entity<IdempotencyKey> {
  const PaymentAttempt._({
    required super.id,
    required this.request,
    required this.outcome,
  });

  /// Opens an attempt under [key].
  ///
  /// A plain constructor rather than a validating factory: every argument is
  /// already a validated value, so a `Result` here would put an unreachable
  /// failure branch at every call site.
  factory PaymentAttempt.intending({
    required IdempotencyKey key,
    required CollectionRequest request,
  }) => PaymentAttempt._(
    id: key,
    request: request,
    outcome: const PaymentOutcome.pending(),
  );

  /// What was to be collected.
  final CollectionRequest request;

  /// How far it got.
  final PaymentOutcome outcome;

  /// How much this intention is for.
  Money get amount => request.amount;

  /// Whether the money has moved and will not move again.
  bool get isSettled => outcome.isSettled;

  /// Whether this attempt still owes the operation money.
  bool get isOutstanding => switch (outcome) {
    PaymentPending() || PaymentRefused() => true,
    PaymentTaken() || PaymentRefunded() => false,
  };

  /// Records that the money changed hands at [at].
  Result<PaymentAttempt, PaymentsFailure> taken({required DateTime at}) {
    if (isSettled) return Failed(AlreadySettled(id.value));
    return Success(_with(PaymentOutcome.taken(at: at.toUtc())));
  }

  /// Records that the far side said no.
  ///
  /// Allowed from a refusal as well as from pending: a customer who tried two
  /// cards produced two refusals under one intention, and the second one is
  /// the useful message.
  Result<PaymentAttempt, PaymentsFailure> refused({required String reason}) {
    if (isSettled) return Failed(AlreadySettled(id.value));
    return Success(_with(PaymentOutcome.refused(reason: reason)));
  }

  /// Records that the money was given back at [at].
  Result<PaymentAttempt, PaymentsFailure> refunded({required DateTime at}) =>
      switch (outcome) {
        PaymentTaken(at: final takenAt) => Success(
          _with(
            PaymentOutcome.refunded(takenAt: takenAt, refundedAt: at.toUtc()),
          ),
        ),
        PaymentRefunded() => Failed(AlreadySettled(id.value)),
        PaymentPending() || PaymentRefused() => const Failed(
          RefundNotPossible(reason: 'the money was never taken'),
        ),
      };

  PaymentAttempt _with(PaymentOutcome next) =>
      PaymentAttempt._(id: id, request: request, outcome: next);

  @override
  String toString() => 'PaymentAttempt(${id.value}, $amount, $outcome)';
}
