import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_mapper.dart';

/// Records the receipt a customer is entitled to.
///
/// **It does not drive a printer, and that is the honest shape rather than a
/// gap.** There is no printer among the eight platform packages phase 2 fixed,
/// and a courier platform's receipt is usually a screen the customer looks at
/// or a message they are sent — hardware is the exception. What "was a receipt
/// produced" needs is a record, which is what this writes.
///
/// An operation that does have a bluetooth roll printer binds a different
/// adapter to `ReceiptPrinterPort` and nothing else in the feature moves.
/// That is the whole reason the port exists for something this small: the
/// question is asked by a regulator, the answer has to be a seam a test can
/// watch, and the technology behind it is somebody else's decision.
///
/// A failure here never undoes a collection — `CollectOnDelivery` logs it and
/// carries on. Money the courier is holding with no record of it is worse than
/// a customer with no slip of paper.
final class KeyValueReceiptPrinter implements ReceiptPrinterPort {
  /// Creates the adapter over [store].
  const KeyValueReceiptPrinter({
    required this.store,
    this.namespace = 'payments.receipt',
  });

  /// Where the receipts go.
  final KeyValueStore store;

  /// The key prefix this adapter owns.
  final String namespace;

  @override
  Future<Result<void, PaymentsFailure>> issue(PaymentAttempt attempt) async {
    final body = jsonEncode(PaymentsMapper.attemptToDto(attempt).toJson());

    // Keyed by the idempotency key, so a retried collection overwrites its own
    // receipt rather than producing a second one. A customer with two receipts
    // for one payment is a customer with a question nobody can answer.
    return switch (await store.write('$namespace.${attempt.id.value}', body)) {
      Failed(:final failure) => Failed(
        PaymentsUnavailable(detail: '$failure'),
      ),
      Success() => const Success(null),
    };
  }
}
