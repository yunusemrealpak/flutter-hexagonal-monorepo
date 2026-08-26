import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:reporting_api/reporting_api.dart';

import 'tally_dto.dart';

/// Keeps the running totals in a key-value store.
///
/// The infrastructure half of this package. It imports no use case, and no use
/// case imports it.
final class KeyValueTallyStore implements TallyStore {
  /// Creates the adapter over the store it keeps totals in.
  const KeyValueTallyStore({required this._store});

  final KeyValueStore _store;

  /// The key this adapter writes.
  static const key = 'reporting.tallies';

  @override
  Future<Result<OperationTally, ReportingFailure>> read(String day) async {
    final held = await _read();
    if (held case Failed(:final failure)) {
      return Failed(failure);
    }

    for (final tally
        in (held as Success<List<OperationTally>, ReportingFailure>).value) {
      if (tally.day.value == day) {
        return Success(tally);
      }
    }

    // A day nobody has recorded anything on is empty, not missing. The parse
    // can still fail — a caller may have asked for something that is not a
    // day at all — and that is the one thing worth reporting here.
    return ReportingDay.parse(day).map(OperationTally.empty);
  }

  @override
  Future<Result<void, ReportingFailure>> put(OperationTally tally) async {
    final held = await _read();
    if (held case Failed(:final failure)) {
      return Failed(failure);
    }

    final stored =
        (held as Success<List<OperationTally>, ReportingFailure>).value;
    final next = [
      ...stored.where((existing) => existing.day != tally.day),
      tally,
    ]..sort((a, b) => a.day.value.compareTo(b.day.value));
    return _write(next);
  }

  @override
  Future<Result<List<String>, ReportingFailure>> days() async {
    final held = await _read();

    return held.map(
      (tallies) => [for (final tally in tallies) tally.day.value]..sort(),
    );
  }

  Future<Result<List<OperationTally>, ReportingFailure>> _read() async {
    final raw = await _store.read(key);

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: null) => const Success([]),
      Success(value: final text?) => switch (TallyDto.decodeAll(text)) {
        null => const Failed(
          TallyUnavailable(detail: 'the stored totals could not be decoded'),
        ),
        final rows => _toDomain(rows),
      },
    };
  }

  Result<List<OperationTally>, ReportingFailure> _toDomain(
    List<TallyDto> rows,
  ) {
    final tallies = <OperationTally>[];
    for (final row in rows) {
      final tally = row.toDomain();
      if (tally case Failed(:final failure)) {
        return Failed(failure);
      }
      tallies.add(
        (tally as Success<OperationTally, ReportingFailure>).value,
      );
    }
    return Success(tallies);
  }

  Future<Result<void, ReportingFailure>> _write(
    List<OperationTally> tallies,
  ) async {
    final written = await _store.write(
      key,
      TallyDto.encodeAll([
        for (final tally in tallies) TallyDto.fromDomain(tally),
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  ReportingFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => TallyUnavailable(detail: 'corrupt at $key'),
    StoreUnavailable(:final detail) => TallyUnavailable(detail: detail),
    StoreOutOfSpace() => const TallyUnavailable(
      detail: 'no room for the totals',
    ),
  };
}
