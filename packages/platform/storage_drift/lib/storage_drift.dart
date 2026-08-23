/// The SQLite schema every Peyk application ships with, and the adapter that
/// puts the `KeyValueStore` port on top of it.
///
/// The package owns two things that are easy to confuse. `PeykDatabase` is a
/// *schema* — tables, migrations, data access objects — and it is deliberately
/// shared: one database per application rather than one per feature, so that a
/// release has one migration history to get right instead of a dozen.
/// `DriftKeyValueStore` is an *adapter*: it implements a port declared in
/// `core_ports` and is the boundary where a `SqliteException` becomes a
/// `StoreFailure`.
///
/// What is not here is as deliberate. No feature's tables: a shipment lives
/// behind a repository in `shipments_infrastructure`, which will declare its
/// own tables against this same database. No `path_provider`, no
/// `sqlite3_flutter_libs`, and no decision about where the file goes — the
/// executor arrives as a constructor argument, which is what keeps this
/// package pure Dart and what lets every test in it run against an in-memory
/// database.
library;

export 'src/drift_key_value_store.dart';
export 'src/key_value_dao.dart';
export 'src/outbox_dao.dart';
export 'src/peyk_database.dart';
export 'src/sqlite_store_failure.dart';
