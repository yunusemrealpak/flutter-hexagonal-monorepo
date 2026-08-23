# storage_drift

The SQLite schema every Peyk application ships with, its migration history, and the drift-backed adapter for the `KeyValueStore` port.

## What it is for

Two things that are easy to confuse, and the distinction is the reason the package is worth reading:

| Type | Kind | Role |
|---|---|---|
| `PeykDatabase` | schema | tables, migrations, data access objects |
| `KeyValueDao`, `OutboxDao` | schema | the statements each table answers |
| `DriftKeyValueStore` | adapter | implements `core_ports.KeyValueStore` |
| `storeFailureFrom` | mapping | `SqliteException` → `sealed StoreFailure` |

`PeykDatabase` is *not* a port implementation. It is a database, and it is deliberately shared: one per application rather than one per feature, so a release has one migration history to get right instead of a dozen, and a cross-feature read can happen inside one transaction.

## What it may depend on

`core_kernel`, `core_ports`, `drift` and `sqlite3`. Not another `platform/*` package — the constitution forbids that edge outright.

`sqlite3` is a direct dependency even though drift already pulls it in, because `storeFailureFrom` imports it to read extended result codes and `depend_on_referenced_packages` is promoted to an error here: `arch_check` treats a pubspec as the truth about what a package uses, and that premise only holds if an import cannot exist without an entry.

`core_testing` is a **dev** dependency, for `FakeClock`. Nothing under `lib/` imports it, so no edge is created in the product graph — see [`docs/DEPENDENCY_RULES.md` §2.0](../../../docs/DEPENDENCY_RULES.md).

## What must never live here

- **A feature's tables.** A shipment belongs behind a repository in `shipments_infrastructure`, which declares its own tables against this same database. A table that arrived from a feature would make the migration history depend on which features an application happens to include.
- **A decision about where the database file goes.** No `path_provider`, no `sqlite3_flutter_libs`. The `QueryExecutor` is a constructor argument, which is what keeps this package pure Dart and lets every test here run in memory.
- **Domain vocabulary.** `OutboxEntries.feature` and `.operation` are opaque strings. That is what lets `sync` carry every feature's writes while depending on none of them — scenario 3 of the architecture.
- **A thrown exception above `DriftKeyValueStore`.** Below the adapter, a DAO is allowed to throw; the adapter is the boundary where it stops.

## The migration history, and why it is three versions

| Version | Change | Cost |
|---|---|---|
| 1 | `key_value_entries` as `(key, value, updated_at)` | — |
| 2 | `outbox_entries` added | new table, existing data untouched |
| 3 | `namespace` added and joined to the primary key | **full table rebuild** |

Version 3 is the one that can lose data. A column with a default can be appended in place; a primary key cannot change without recreating the table and copying every row. `m.alterTable` does the copy, and `test/migration_test.dart` exists because "drift does the copy" is a claim about drift, not a checked fact about this schema.

The test describes the old schema as **raw SQL**, not in terms of the current table classes. A migration test written against the new definitions proves nothing: the same mistake would be present on both sides of the comparison.

`onUpgrade` is written as a sequence of `if (from < n)` steps rather than a switch on `from`. A device that skipped a release arrives several versions behind, and a switch is how you ship an app that upgrades 2→3 correctly and 1→3 not at all.

## Timestamps are stored as text, on purpose

`build.yaml` sets `store_date_time_values_as_text: true`. With drift's default integer storage, a value written as `2026-01-01T12:00Z` reads back as `2026-01-01T15:00` local — the same instant, a different object, and `DateTime.==` compares the UTC flag too.

`Clock` promises UTC. An adapter that quietly converted would break that promise one layer below where anyone would look for it, and every comparison against a server timestamp would be off by whatever the device's offset happened to be. Text costs a few bytes per row and keeps the round trip honest.
