import 'package:drift/drift.dart';

/// The rows behind the `KeyValueStore` port.
///
/// Small durable values — a sync cursor, a chosen language, the last route a
/// courier was on. Not domain data: a shipment lives behind a repository in
/// `shipments_infrastructure` where it can be typed, indexed and migrated on
/// its own schedule. A feature that persists entities here has skipped
/// designing its repository, and rule §2 of `core_ports` says so out loud.
///
/// [namespace] arrived in schema version 3 and is the reason that migration is
/// worth reading: it is part of the primary key, so adding it rebuilt the
/// table rather than appending a column. `test/migration_test.dart` proves the
/// rows survived it.
@DataClassName('KeyValueEntry')
class KeyValueEntries extends Table {
  /// Which subsystem owns the entry.
  ///
  /// Two features are allowed to store `cursor` without colliding, and signing
  /// out can clear one namespace without touching the others.
  TextColumn get namespace => text().withDefault(const Constant('default'))();

  /// The key, unique within its [namespace].
  TextColumn get key => text()();

  /// The stored value. Always text: the port stores strings, and anything
  /// richer is a caller's encoding decision.
  TextColumn get value => text()();

  /// When the value was last written, in UTC.
  ///
  /// Written from the injected `Clock`, never from `DateTime.now()`, which is
  /// what lets a test assert on it.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {namespace, key};
}
