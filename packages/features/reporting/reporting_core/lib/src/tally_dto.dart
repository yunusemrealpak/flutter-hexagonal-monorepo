import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// The stored shape of one day's totals.
///
/// It stores the **outcomes**, not the counts, for the same reason
/// `OperationTally` holds them: a stored count is a number that can disagree
/// with the thing it counts, and a stored count read back into a tally that
/// recomputes would be two answers to one question.
///
/// The cost is a row per parcel per day, which for an operation counting
/// hundreds of parcels is a few kilobytes and for one counting millions is the
/// point at which this store moves behind an API. The port is what makes that
/// a composition-root change.
final class TallyDto {
  /// Creates the DTO.
  const TallyDto({required this.day, required this.outcomes});

  /// Builds the DTO that carries [tally].
  factory TallyDto.fromDomain(OperationTally tally) => TallyDto(
    day: tally.day.value,
    outcomes: {
      for (final entry in tally.outcomes.entries)
        entry.key.value: entry.value.name,
    },
  );

  /// Reads one from a decoded JSON object, or `null` when the shape is wrong.
  static TallyDto? fromJson(Map<String, Object?> json) {
    final day = json['day'];
    final outcomes = json['outcomes'];
    if (day is! String || outcomes is! Map<String, Object?>) {
      return null;
    }

    final read = <String, String>{};
    for (final entry in outcomes.entries) {
      final value = entry.value;
      if (value is! String) {
        return null;
      }
      read[entry.key] = value;
    }
    return TallyDto(day: day, outcomes: read);
  }

  /// Reads every stored day from the text a key-value store gave back.
  static List<TallyDto>? decodeAll(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final rows = <TallyDto>[];
      for (final element in decoded) {
        if (element is! Map<String, Object?>) {
          return null;
        }
        final dto = fromJson(element);
        if (dto == null) {
          return null;
        }
        rows.add(dto);
      }
      return rows;
    } on FormatException {
      return null;
    }
  }

  /// The text to store for [rows].
  static String encodeAll(List<TallyDto> rows) => jsonEncode([
    for (final row in rows) {'day': row.day, 'outcomes': row.outcomes},
  ]);

  /// Which day, as stored.
  final String day;

  /// How each parcel ended, keyed by identifier.
  final Map<String, String> outcomes;

  /// The tally this DTO carries, or the first failure that stopped it.
  Result<OperationTally, ReportingFailure> toDomain() {
    final parsed = <ShipmentId, ShipmentOutcome>{};
    for (final entry in outcomes.entries) {
      final shipment = ShipmentId.parse(entry.key);
      if (shipment case Failed()) {
        return Failed(
          MalformedTally(
            field: 'outcomes',
            reason: '"${entry.key}" is not a shipment identifier',
          ),
        );
      }
      final outcome = ShipmentOutcome.parse(entry.value);
      if (outcome case Failed(:final failure)) {
        return Failed(failure);
      }
      parsed[(shipment as Success<ShipmentId, ShipmentFailure>).value] =
          (outcome as Success<ShipmentOutcome, ReportingFailure>).value;
    }

    return ReportingDay.parse(day).flatMap(
      (reportingDay) =>
          OperationTally.stored(day: reportingDay, outcomes: parsed),
    );
  }
}
