import 'package:core_kernel/core_kernel.dart';
import 'package:reporting_api/reporting_api.dart';

import 'read_range.dart';

/// The one implementation of `ReportingFacade`.
///
/// Read-only, like the port. Everything that changes a number arrives on the
/// bus and goes through `ShipmentOutcomeWatcher`, which is not on this
/// surface — nothing outside the feature can add to a total.
final class ReportingCoordinator implements ReportingFacade {
  /// Creates the coordinator.
  const ReportingCoordinator({required this._store, required this._range});

  final TallyStore _store;
  final ReadRange _range;

  @override
  Future<Result<OperationTally, ReportingFailure>> tallyFor(
    ReportingDay day,
  ) => _store.read(day.value);

  @override
  Future<Result<List<OperationTally>, ReportingFailure>> range({
    required ReportingDay from,
    required ReportingDay to,
  }) => _range(ReadRangeCommand(from: from, to: to));
}
