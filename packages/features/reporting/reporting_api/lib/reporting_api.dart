/// The reporting contract: what a day of the operation adds up to, and the
/// port that keeps the running total.
///
/// **The tally holds outcomes per parcel, not counters.** Every number on it
/// is computed from that map on read. A stored counter beside the thing it
/// counts is a state that can disagree with itself, and it disagrees
/// silently — the same reason `LoadCount` derives its discrepancy rather than
/// storing it.
///
/// Two behaviours fall out of that, and the operation needs both: recording
/// the same parcel twice changes nothing, and a parcel that failed at eleven
/// and was delivered at four counts once, as delivered.
///
/// **The facade is read-only.** `reporting_core` builds these totals by
/// listening to domain events; nothing outside the feature tells it what
/// happened. A `record` method here would be an invitation for a screen to add
/// a number the operation never produced.
///
/// **A day is UTC**, and that is a decision with a cost: a round that runs
/// past local midnight is split. The alternative makes a tally that cannot be
/// summed across a fleet without knowing where every courier was standing.
library;

export 'src/entities/operation_tally.dart';
export 'src/failures/reporting_failure.dart';
export 'src/ports/driven/tally_store.dart';
export 'src/ports/driving/reporting_facade.dart';
export 'src/values/reporting_day.dart';
export 'src/values/shipment_outcome.dart';
