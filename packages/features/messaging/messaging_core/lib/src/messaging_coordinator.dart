import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

import 'drain_queue.dart';
import 'mark_thread_read.dart';
import 'read_thread.dart';
import 'send_message.dart';

/// The one implementation of `MessagingFacade`.
///
/// It composes use cases and owns the change stream. The stream carries a
/// `ThreadId` rather than a thread: a subscriber that wants the messages asks
/// for them, and a stream that carried lists would redraw every screen holding
/// one whenever any of them changed.
final class MessagingCoordinator implements MessagingFacade {
  /// Creates the coordinator over its use cases.
  MessagingCoordinator({
    required this._read,
    required this._send,
    required this._mark,
    required this._drain,
  });

  final ReadThread _read;
  final SendMessage _send;
  final MarkThreadRead _mark;
  final DrainQueue _drain;

  final StreamController<ThreadId> _changes =
      StreamController<ThreadId>.broadcast();

  @override
  Future<Result<List<Message>, MessagingFailure>> read(ThreadId thread) =>
      _read(thread);

  @override
  Future<Result<Message, MessagingFailure>> send({
    required ThreadId thread,
    required ActorId author,
    required String body,
  }) async {
    final sent = await _send(
      SendMessageCommand(thread: thread, author: author, body: body),
    );
    if (sent case Success()) {
      _announce(thread);
    }
    return sent;
  }

  @override
  Future<Result<List<Message>, MessagingFailure>> markRead({
    required ThreadId thread,
    required ActorId reader,
  }) async {
    final marked = await _mark(
      MarkThreadReadCommand(thread: thread, reader: reader),
    );
    if (marked case Success()) {
      _announce(thread);
    }
    return marked;
  }

  @override
  Stream<ThreadId> changes() => _changes.stream;

  /// Sends everything waiting, and announces every thread that moved.
  ///
  /// Not on the facade, because it is not something a screen asks for: an app
  /// calls it when connectivity returns, which is a composition-root concern
  /// and the one place `NetworkStatus` belongs.
  Future<Result<List<Message>, MessagingFailure>> drain() async {
    final sent = await _drain(());
    if (sent case Success(:final value)) {
      value.map((message) => message.thread).toSet().forEach(_announce);
    }
    return sent;
  }

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();

  void _announce(ThreadId thread) {
    if (!_changes.isClosed) {
      _changes.add(thread);
    }
  }
}
