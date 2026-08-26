import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:notifications_api/notifications_api.dart';

import 'inbox_entry_dto.dart';

/// Keeps one person's alerts in a key-value store.
///
/// The inbox half of this package's infrastructure. It imports no use case,
/// and no use case imports it — the rule a full split gets from the compiler
/// and a reduced split keeps by hand.
///
/// It never sees `identity_api`: `InboxStore` promises a `String`, and an
/// adapter that took an `ActorId` would be one that could not move into an
/// `_infrastructure` package the day this feature splits.
///
/// One key holds the whole inbox rather than one key per alert. An inbox is
/// read and written whole — a courier opens it, and the unread count
/// recomputes from all of it — so splitting it across keys would buy nothing
/// and cost a `keys()` scan on every read.
final class KeyValueInboxStore implements InboxStore {
  /// Creates the adapter over the store it keeps inboxes in.
  const KeyValueInboxStore({required this._store});

  final KeyValueStore _store;

  /// The prefix every key this adapter writes carries.
  ///
  /// A namespace rather than a bare actor identifier: the store is shared with
  /// every other feature that keeps a scalar, and two features choosing the
  /// same key would silently overwrite each other.
  static const keyPrefix = 'notifications.inbox.';

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> entriesFor(
    String actorId,
  ) => _read(actorId);

  @override
  Future<Result<void, NotificationsFailure>> put(
    String actorId,
    InboxEntry entry,
  ) async {
    final read = await _read(actorId);
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored =
        (read as Success<List<InboxEntry>, NotificationsFailure>).value;

    // At-least-once delivery means the same alert arrives twice. The second
    // copy knows nothing about a read mark the first one may already carry, so
    // the stored entry wins and the arrival is dropped.
    if (_indexOf(stored, entry) >= 0) {
      return const Success(null);
    }

    return _write(actorId, [entry, ...stored]);
  }

  @override
  Future<Result<void, NotificationsFailure>> update(
    String actorId,
    InboxEntry entry,
  ) async {
    final read = await _read(actorId);
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored =
        (read as Success<List<InboxEntry>, NotificationsFailure>).value;

    final index = _indexOf(stored, entry);
    if (index < 0) {
      return Failed(NotificationMissing(entry.id.value));
    }

    return _write(actorId, [...stored]..[index] = entry);
  }

  /// Where [entry] sits in [stored], by identifier.
  ///
  /// Written out rather than `stored.indexOf(entry)`, even though `Entity`
  /// equality is by identifier and the two agree today. The question this
  /// adapter asks is "is this alert already here", and spelling it as identity
  /// keeps the answer independent of a later decision to give `InboxEntry`
  /// field equality — which would silently turn `put` into a duplicating
  /// append.
  int _indexOf(List<InboxEntry> stored, InboxEntry entry) =>
      stored.indexWhere((held) => held.id == entry.id);

  Future<Result<List<InboxEntry>, NotificationsFailure>> _read(
    String actorId,
  ) async {
    final raw = await _store.read('$keyPrefix$actorId');

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      // A key that holds nothing is an empty inbox, which is the state most
      // inboxes are in. It is not a failure and it is not a missing row.
      Success(value: null) => const Success([]),
      Success(value: final text?) => switch (InboxEntryDto.decodeAll(text)) {
        null => const Failed(
          InboxUnavailable(detail: 'the stored inbox could not be decoded'),
        ),
        final dtos => _toDomain(dtos),
      },
    };
  }

  /// Turns every stored row into an entry, refusing the whole inbox if one of
  /// them cannot be read.
  ///
  /// All or nothing on purpose. Returning the rows that parsed would show a
  /// courier an inbox quietly missing an assignment, and the next write would
  /// persist the gap.
  Result<List<InboxEntry>, NotificationsFailure> _toDomain(
    List<InboxEntryDto> dtos,
  ) {
    final entries = <InboxEntry>[];
    for (final dto in dtos) {
      final entry = dto.toDomain();
      if (entry case Failed(:final failure)) {
        return Failed(failure);
      }
      entries.add((entry as Success<InboxEntry, NotificationsFailure>).value);
    }
    return Success(entries);
  }

  Future<Result<void, NotificationsFailure>> _write(
    String actorId,
    List<InboxEntry> entries,
  ) async {
    final written = await _store.write(
      '$keyPrefix$actorId',
      InboxEntryDto.encodeAll([
        for (final entry in entries) InboxEntryDto.fromDomain(entry),
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  NotificationsFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => InboxUnavailable(detail: 'corrupt at $key'),
    StoreUnavailable(:final detail) => InboxUnavailable(detail: detail),
    StoreOutOfSpace() => const InboxUnavailable(
      detail: 'no room to store the inbox',
    ),
  };
}
