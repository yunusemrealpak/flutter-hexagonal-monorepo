import 'package:core_kernel/core_kernel.dart';

import '../../entities/operation_tally.dart';
import '../../failures/reporting_failure.dart';

/// Where the running totals are kept.
///
/// A driven port taking a raw day identifier, for the reason §2.1 gives about
/// driven ports — though here the type it would otherwise name is this
/// feature's own, so the rule costs nothing and buys consistency.
///
/// `read` answers an **empty tally** for a day nobody has recorded anything
/// on, not a failure and not `null`. A day with nothing in it is the state
/// every day is in until the first parcel is finished, and making each caller
/// re-decide what absence means is how three screens end up with three
/// answers.
abstract interface class TallyStore {
  /// The tally for [day], empty when nothing has been recorded.
  Future<Result<OperationTally, ReportingFailure>> read(String day);

  /// Stores [tally], replacing the day's previous total.
  Future<Result<void, ReportingFailure>> put(OperationTally tally);

  /// Every day this device has totals for, oldest first.
  Future<Result<List<String>, ReportingFailure>> days();
}
