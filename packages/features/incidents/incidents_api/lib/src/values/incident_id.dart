import 'package:core_kernel/core_kernel.dart';

import '../failures/incidents_failure.dart';

/// Identifies one recorded exception.
///
/// Minted by `IdGenerator` when an incident is opened — never derived from the
/// shipment. A parcel can go wrong twice: damaged on Tuesday, refused on
/// Thursday. An identifier derived from the shipment would make the second
/// record overwrite the first, and the claim against the carrier would be
/// missing its evidence.
final class IncidentId extends ValueObject<String> {
  const IncidentId._(super.value);

  /// Reads an incident identifier from [raw].
  static Result<IncidentId, IncidentsFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedIncident(field: 'id', reason: 'it is empty'),
      );
    }
    return Success(IncidentId._(trimmed));
  }
}
