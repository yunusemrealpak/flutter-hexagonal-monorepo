@Tags(['unit'])
library;

import 'package:core_ports/core_ports.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:test/test.dart';

SqliteException _sqlite(int extendedResultCode, String message) =>
    SqliteException(extendedResultCode: extendedResultCode, message: message);

void main() {
  group('storeFailureFrom', () {
    test('maps a full disk to StoreOutOfSpace', () {
      final failure = storeFailureFrom(
        _sqlite(13, 'database or disk is full'),
        key: 'locale',
      );

      expect(failure, isA<StoreOutOfSpace>());
    });

    test('maps corruption to StoreCorrupted, naming the key', () {
      final failure = storeFailureFrom(
        _sqlite(11, 'database disk image is malformed'),
        key: 'sync.cursor',
      );

      expect(failure, isA<StoreCorrupted>());
      expect((failure as StoreCorrupted).key, 'sync.cursor');
    });

    test('maps a file that is not a database to StoreCorrupted', () {
      expect(
        storeFailureFrom(_sqlite(26, 'file is not a database'), key: 'k'),
        isA<StoreCorrupted>(),
      );
    });

    test('reads the primary code out of an extended one', () {
      // SQLITE_IOERR_WRITE is 778: 10 in the low byte, 3 in the high. One
      // branch has to cover SQLITE_IOERR and all twenty-odd of its forms, and
      // the mask is what makes that possible.
      final failure = storeFailureFrom(
        _sqlite(778, 'disk I/O error'),
        key: 'k',
      );

      expect(failure, isA<StoreUnavailable>());
      expect((failure as StoreUnavailable).detail, 'disk I/O error');
    });

    test('maps anything that is not a sqlite error to StoreUnavailable', () {
      final failure = storeFailureFrom(StateError('closed'), key: 'k');

      // The catch-all exists so that nothing escapes the adapter, not so that
      // mapping can be skipped.
      expect(failure, isA<StoreUnavailable>());
    });
  });
}
