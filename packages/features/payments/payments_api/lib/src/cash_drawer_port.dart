import 'package:core_kernel/core_kernel.dart';

import 'money.dart';
import 'payments_failure.dart';

/// The money a courier is physically holding.
///
/// A driven port, and a small one: it records that notes went in or came out,
/// so that the amount in a bag can be reconciled against the amount in a
/// settlement at the end of a day. It is not a hardware contract — a courier's
/// "drawer" is a pouch — and it is not a ledger; the ledger is `Settlement`.
///
/// It speaks in `Money` because that is what a courier is holding. An adapter
/// that talks to a terminal with a real drawer translates; one that keeps a
/// running total on the device does not have to.
abstract interface class CashDrawerPort {
  /// Records that [amount] was taken at a door.
  Future<Result<void, PaymentsFailure>> accept(Money amount);

  /// Records that [amount] was handed back.
  Future<Result<void, PaymentsFailure>> release(Money amount);

  /// What the courier should be holding.
  ///
  /// Read at the end of a day and compared with the settlement. A difference
  /// is not a failure here — it is a fact somebody has to explain, and this
  /// port's job is to report the number rather than to judge it.
  Future<Result<Money, PaymentsFailure>> balance();
}
