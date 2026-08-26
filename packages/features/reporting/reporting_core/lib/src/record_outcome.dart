import 'package:core_kernel/core_kernel.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Which parcel ended how, and when it happened.
final class RecordOutcomeCommand {
  /// Creates the command.
  const RecordOutcomeCommand({
    required this.shipment,
    required this.outcome,
    required this.occurredAt,
  });

  /// Which parcel.
  final ShipmentId shipment;

  /// How it ended.
  final ShipmentOutcome outcome;

  /// When it happened, in domain time.
  ///
  /// The instant off the event, not the instant this device processed it. A
  /// tally attributed by processing time would move a delivery into today
  /// because a phone was switched on this morning, and yesterday's total would
  /// change after somebody had already read it.
  final DateTime occurredAt;
}

/// Adds one finished parcel to the day it finished on.
///
/// Read, record, write. Every interesting property of this belongs to
/// `OperationTally` — recording twice changes nothing, and the last outcome
/// wins — which is why this use case has no branch of its own.
///
/// There is no `Clock` here, and there should not be: this feature never asks
/// what time it is. Every instant it uses arrives on an event.
final class RecordOutcome
    implements
        UseCase<
          RecordOutcomeCommand,
          Result<OperationTally, ReportingFailure>
        > {
  /// Creates the use case.
  const RecordOutcome({required this._store});

  final TallyStore _store;

  @override
  Future<Result<OperationTally, ReportingFailure>> call(
    RecordOutcomeCommand command,
  ) async {
    final day = ReportingDay.of(command.occurredAt);

    final held = await _store.read(day.value);
    if (held case Failed(:final failure)) {
      return Failed(failure);
    }

    final next = (held as Success<OperationTally, ReportingFailure>).value
        .recording(shipment: command.shipment, outcome: command.outcome);
    final written = await _store.put(next);

    return switch (written) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(next),
    };
  }
}
