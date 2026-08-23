import 'package:core_ports/core_ports.dart';
import 'package:sqlite3/sqlite3.dart';

// sqlite's primary result codes. The library exposes them only as integers, so
// they are named here rather than left as magic numbers in a switch.
// https://www.sqlite.org/rescode.html
const int _sqliteCorrupt = 11;
const int _sqliteFull = 13;
const int _sqliteNotADatabase = 26;

/// Translates whatever sqlite threw into the `sealed` failure the
/// `KeyValueStore` port declares.
///
/// Exported rather than kept private because every `_infrastructure` package
/// that persists with drift needs exactly this translation, and three copies
/// of it would drift apart at the first sqlite upgrade. It is the one piece of
/// this package that has no drift in it — only the mapping from a technology's
/// error vocabulary to the product's.
///
/// [key] is what a [StoreCorrupted] failure will name. A caller that is not
/// operating on a single key passes the namespace it was working in; the point
/// of the field is to make the log say where the bad data is.
///
/// Three cases are distinguished and the rest collapse, because three are what
/// a caller behaves differently about: a full disk asks the user to free
/// space, corruption means the value is gone and retrying will not bring it
/// back, and everything else is worth one retry.
StoreFailure storeFailureFrom(Object error, {required String key}) {
  if (error is SqliteException) {
    // The extended code carries the primary code in its low byte. Masking
    // rather than comparing lets one branch cover SQLITE_IOERR and all
    // twenty-odd of its extended forms.
    return switch (error.extendedResultCode & 0xFF) {
      _sqliteFull => const StoreOutOfSpace(),
      _sqliteCorrupt || _sqliteNotADatabase => StoreCorrupted(key),
      _ => StoreUnavailable(detail: error.message),
    };
  }
  return StoreUnavailable(detail: error.toString());
}
