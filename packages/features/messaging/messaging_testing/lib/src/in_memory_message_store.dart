import 'dart:collection';

import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';

/// A [MessageStore] that really stores.
///
/// A fake, not a mock: it keeps messages, replaces by identifier and returns
/// them in the order the contract promises. A test written against it
/// exercises the caller's logic rather than a script of expected calls.
///
/// [failNextWith] is what makes the failure branches testable. Failure is part
/// of the port's contract, so the fake that stands in for that contract has to
/// be able to produce it — otherwise every caller's failure path stays
/// untested.
final class InMemoryMessageStore implements MessageStore {
  final Map<String, Message> _messages = {};

  final Queue<MessagingFailure> _queuedFailures = Queue();

  /// Makes the next call fail with [failure].
  ///
  /// A queue rather than a single slot, so a test can fail two calls in a row
  /// — which is what a caller that reads before it writes needs in order to
  /// exercise both of its failure branches.
  void failNextWith(MessagingFailure failure) => _queuedFailures.add(failure);

  /// Everything stored, in insertion order. For assertions.
  List<Message> get all => List.unmodifiable(_messages.values);

  @override
  Future<Result<List<Message>, MessagingFailure>> thread(
    String threadId,
  ) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    return Success(
      _messages.values.where((m) => m.thread.value == threadId).toList()
        ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt)),
    );
  }

  @override
  Future<Result<void, MessagingFailure>> put(Message message) async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    _messages[message.id.value] = message;
    return const Success(null);
  }

  @override
  Future<Result<List<Message>, MessagingFailure>> queued() async {
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    return Success(
      _messages.values.where((m) => m.isQueued).toList()
        ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt)),
    );
  }

  MessagingFailure? _taken() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeFirst();
}
