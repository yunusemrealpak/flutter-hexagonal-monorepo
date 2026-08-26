import 'package:core_kernel/core_kernel.dart';

import 'payments_failure.dart';
import 'settlement.dart';

/// Where a courier's day is kept between the first collection and the
/// hand-in.
///
/// A driven port. It reads and writes whole settlements rather than deltas:
/// the entity has already decided what the day became, and sending "what
/// changed" would make the far side re-derive a decision this side made.
///
/// Identifiers arrive raw, like every driven port's in this workspace.
abstract interface class SettlementStore {
  /// Reads the settlement for [settlementId], or `null` when the day has not
  /// been opened.
  ///
  /// A missing day is a successful read of nothing rather than a failure. A
  /// courier's first collection of the morning arrives before anything has
  /// been written, and reporting that as an error would make every shift start
  /// with one.
  Future<Result<Settlement?, PaymentsFailure>> read(String settlementId);

  /// Stores [settlement], replacing whatever was there.
  Future<Result<Settlement, PaymentsFailure>> save(Settlement settlement);
}
