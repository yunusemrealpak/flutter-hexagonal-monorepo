// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value_dao.dart';

// ignore_for_file: type=lint
mixin _$KeyValueDaoMixin on DatabaseAccessor<PeykDatabase> {
  $KeyValueEntriesTable get keyValueEntries => attachedDatabase.keyValueEntries;
  KeyValueDaoManager get managers => KeyValueDaoManager(this);
}

class KeyValueDaoManager {
  final _$KeyValueDaoMixin _db;
  KeyValueDaoManager(this._db);
  $$KeyValueEntriesTableTableManager get keyValueEntries =>
      $$KeyValueEntriesTableTableManager(
        _db.attachedDatabase,
        _db.keyValueEntries,
      );
}
