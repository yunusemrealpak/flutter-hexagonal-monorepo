import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/reporting_failure.dart';
import '../values/reporting_day.dart';
import '../values/shipment_outcome.dart';

/// What one day of the operation adds up to.
///
/// **It holds outcomes per parcel, not counters.** `delivered` is
/// `outcomes.values.where(...).length`, computed on every read, and the reason
/// is the same one `LoadCount` gives for deriving its discrepancy: a stored
/// counter beside the thing it counts is a state that can disagree with
/// itself, and it disagrees silently.
///
/// Two consequences fall out of that, and both are behaviour the operation
/// actually needs:
///
/// - **Recording the same parcel twice changes nothing.** A read model built
///   from events is exposed to the same event arriving twice, and a counter
///   would have counted it twice.
/// - **A parcel can change its mind.** A failed attempt at eleven and a
///   successful one at four is one parcel that was *delivered*; the last
///   outcome wins, and a pair of counters would have to remember to decrement
///   one of them.
final class OperationTally extends Entity<ReportingDay> {
  const OperationTally._({required super.id, required this.outcomes});

  /// An empty day.
  factory OperationTally.empty(ReportingDay day) =>
      OperationTally._(id: day, outcomes: const {});

  /// Rebuilds a stored tally.
  static Result<OperationTally, ReportingFailure> stored({
    required ReportingDay day,
    required Map<ShipmentId, ShipmentOutcome> outcomes,
  }) => Success(
    OperationTally._(id: day, outcomes: Map.unmodifiable(outcomes)),
  );

  /// How every parcel counted today ended.
  final Map<ShipmentId, ShipmentOutcome> outcomes;

  /// Which day this is.
  ReportingDay get day => id;

  /// How many parcels were handed over.
  int get delivered => _count(ShipmentOutcome.delivered);

  /// How many attempts did not end in a hand-over.
  int get failed => _count(ShipmentOutcome.failed);

  /// How many came back to the depot.
  int get returned => _count(ShipmentOutcome.returned);

  /// How many parcels reached an outcome at all.
  int get total => outcomes.length;

  /// The share of finished parcels that were delivered, between 0 and 1.
  ///
  /// Zero for a day with nothing in it, rather than a division by zero or a
  /// `null`. A dispatcher opening the board at six in the morning is looking
  /// at a day that has not happened yet, and "0%" is the honest reading of
  /// that — every other answer needs a footnote.
  double get successRate => total == 0 ? 0 : delivered / total;

  /// Records how [shipment] ended.
  ///
  /// The last outcome wins. Nothing is rejected: an event arriving out of
  /// order is not something a read model can detect without a clock it does
  /// not have, and refusing the second one would freeze a parcel in whichever
  /// outcome happened to arrive first.
  OperationTally recording({
    required ShipmentId shipment,
    required ShipmentOutcome outcome,
  }) => OperationTally._(
    id: id,
    outcomes: Map.unmodifiable({...outcomes, shipment: outcome}),
  );

  int _count(ShipmentOutcome outcome) =>
      outcomes.values.where((held) => held == outcome).length;
}
