import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:incidents_api/incidents_api.dart';

import 'incident_dto.dart';

/// Keeps the incident log in a key-value store.
///
/// The infrastructure half of this package. It imports no use case, and no use
/// case imports it — the rule a full split gets from the compiler and a
/// reduced split keeps by hand.
///
/// One key holds the whole log. That is the right shape for a device that
/// records a handful of exceptions a day and reads them all at once, and it is
/// the wrong shape for an operations backend — which is exactly why the port
/// exists: swapping this for an HTTP adapter is a composition-root change.
final class KeyValueIncidentLog implements IncidentLog {
  /// Creates the adapter over the store it keeps the log in.
  const KeyValueIncidentLog({required this._store});

  final KeyValueStore _store;

  /// The key this adapter writes.
  static const key = 'incidents.log';

  @override
  Future<Result<List<Incident>, IncidentsFailure>> all() => _read();

  @override
  Future<Result<void, IncidentsFailure>> open(Incident incident) async {
    final read = await _read();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored = (read as Success<List<Incident>, IncidentsFailure>).value;

    // Writing an identifier that is already present is a retry of the same
    // write, not a second incident: identifiers are minted per incident.
    if (stored.any((held) => held.id == incident.id)) {
      return const Success(null);
    }

    return _write([incident, ...stored]);
  }

  @override
  Future<Result<void, IncidentsFailure>> update(Incident incident) async {
    final read = await _read();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored = (read as Success<List<Incident>, IncidentsFailure>).value;

    final index = stored.indexWhere((held) => held.id == incident.id);
    if (index < 0) {
      return Failed(IncidentMissing(incident.id.value));
    }

    return _write([...stored]..[index] = incident);
  }

  Future<Result<List<Incident>, IncidentsFailure>> _read() async {
    final raw = await _store.read(key);

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      // Nothing stored is an empty log, which is what a good day looks like.
      Success(value: null) => const Success([]),
      Success(value: final text?) => switch (IncidentDto.decodeAll(text)) {
        null => const Failed(
          IncidentLogUnavailable(detail: 'the stored log could not be decoded'),
        ),
        final rows => _toDomain(rows),
      },
    };
  }

  /// Turns every row into an incident, refusing the whole log if one of them
  /// cannot be read.
  ///
  /// All or nothing. Returning the rows that parsed would show a dispatcher a
  /// board that is quietly missing a damage claim, and the next write would
  /// persist the gap.
  Result<List<Incident>, IncidentsFailure> _toDomain(List<IncidentDto> rows) {
    final incidents = <Incident>[];
    for (final row in rows) {
      final incident = row.toDomain();
      if (incident case Failed(:final failure)) {
        return Failed(failure);
      }
      incidents.add((incident as Success<Incident, IncidentsFailure>).value);
    }
    return Success(incidents);
  }

  Future<Result<void, IncidentsFailure>> _write(List<Incident> log) async {
    final written = await _store.write(
      key,
      IncidentDto.encodeAll([
        for (final incident in log) IncidentDto.fromDomain(incident),
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  IncidentsFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => IncidentLogUnavailable(
      detail: 'corrupt at $key',
    ),
    StoreUnavailable(:final detail) => IncidentLogUnavailable(detail: detail),
    StoreOutOfSpace() => const IncidentLogUnavailable(
      detail: 'no room to store the log',
    ),
  };
}
