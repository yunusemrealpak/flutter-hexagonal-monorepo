import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:messaging_api/messaging_api.dart';

import 'message_dto.dart';

/// Keeps every thread this device knows about in a key-value store.
///
/// One key holds them all, and the queue is a filter over the same list rather
/// than a second key. That is the storage-level statement of the decision in
/// `messaging_api`: a queued message is a stored message with no `sentAt`, so
/// there is no second list to keep in step.
///
/// The kit in `messaging_testing` is what holds this adapter and the in-memory
/// fake to the same behaviour — ordering included, which is the half an
/// implementation gets wrong by returning whatever the map iterated.
final class KeyValueMessageStore implements MessageStore {
  /// Creates the adapter over the store it keeps threads in.
  const KeyValueMessageStore({required this._store});

  final KeyValueStore _store;

  /// The key this adapter writes.
  static const key = 'messaging.threads';

  @override
  Future<Result<List<Message>, MessagingFailure>> thread(
    String threadId,
  ) async {
    final read = await _read();

    return read.map(
      (messages) =>
          messages.where((m) => m.thread.value == threadId).toList()
            ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt)),
    );
  }

  @override
  Future<Result<void, MessagingFailure>> put(Message message) async {
    final read = await _read();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored = (read as Success<List<Message>, MessagingFailure>).value;

    final index = stored.indexWhere((held) => held.id == message.id);
    final next = [...stored];
    if (index < 0) {
      next.add(message);
    } else {
      next[index] = message;
    }
    return _write(next);
  }

  @override
  Future<Result<List<Message>, MessagingFailure>> queued() async {
    final read = await _read();

    return read.map(
      (messages) =>
          messages.where((m) => m.isQueued).toList()
            ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt)),
    );
  }

  Future<Result<List<Message>, MessagingFailure>> _read() async {
    final raw = await _store.read(key);

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: null) => const Success([]),
      Success(value: final text?) => switch (MessageDto.decodeAll(text)) {
        null => const Failed(
          ThreadUnavailable(detail: 'the stored threads could not be decoded'),
        ),
        final rows => _toDomain(rows),
      },
    };
  }

  Result<List<Message>, MessagingFailure> _toDomain(List<MessageDto> rows) {
    final messages = <Message>[];
    for (final row in rows) {
      final message = row.toDomain();
      if (message case Failed(:final failure)) {
        return Failed(failure);
      }
      messages.add((message as Success<Message, MessagingFailure>).value);
    }
    return Success(messages);
  }

  Future<Result<void, MessagingFailure>> _write(List<Message> messages) async {
    final written = await _store.write(
      key,
      MessageDto.encodeAll([
        for (final message in messages) MessageDto.fromDomain(message),
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  MessagingFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => ThreadUnavailable(detail: 'corrupt at $key'),
    StoreUnavailable(:final detail) => ThreadUnavailable(detail: detail),
    StoreOutOfSpace() => const ThreadUnavailable(
      detail: 'no room to store the thread',
    ),
  };
}
