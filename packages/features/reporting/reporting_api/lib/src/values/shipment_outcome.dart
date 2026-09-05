import 'package:core_kernel/core_kernel.dart';

import '../failures/reporting_failure.dart';

/// How a parcel's day ended.
///
/// Three outcomes and no "in progress": a parcel that is still out is not in
/// the tally at all. A fourth member for it would put every undelivered parcel
/// in the denominator of a success rate that is being watched at eleven in the
/// morning, and the number would climb through the day for no reason anybody
/// caused.
enum ShipmentOutcome {
  /// It was handed over.
  delivered,

  /// An attempt was made and it did not happen.
  failed,

  /// It came back to the depot.
  returned;

  /// Reads an outcome from its stored spelling.
  static Result<ShipmentOutcome, ReportingFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedTally(
        field: 'outcome',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
