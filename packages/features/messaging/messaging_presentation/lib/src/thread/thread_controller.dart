import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

import 'thread_state.dart';

/// Drives one thread.
///
/// It holds one port — `MessagingFacade` — and no implementation. Whether the
/// message it sends went over the wire or into a queue is something this
/// package can only observe, never decide.
final class ThreadController extends ChangeNotifier {
  /// Creates the controller for one conversation.
  ThreadController({
    required this._messaging,
    required this._thread,
    required this._reader,
  });

  final MessagingFacade _messaging;
  final ThreadId _thread;
  final ActorId _reader;

  StreamSubscription<ThreadId>? _changes;

  ThreadState _state = const ThreadIdle();

  /// What the screen should be showing.
  ThreadState get state => _state;

  /// Follows changes to this thread, and ignores the others.
  ///
  /// The facade announces every thread that moves, because one connection
  /// coming back drains messages across several. Filtering here rather than
  /// there is what lets two thread screens exist at once without either of
  /// them redrawing for the other's traffic.
  void watch() {
    _changes ??= _messaging.changes().listen((thread) {
      if (thread == _thread) {
        unawaited(load());
      }
    });
  }

  /// Reads the thread.
  Future<void> load() async {
    if (_state is ThreadIdle) {
      _emit(const ThreadLoading());
    }
    _emit(_settled(await _messaging.read(_thread)));
  }

  /// Writes a message.
  ///
  /// Does not reload afterwards: the facade announces the thread, and the
  /// subscription this controller already holds does the reading. Reloading
  /// here as well would read the thread twice for every message somebody
  /// types.
  Future<void> send(String body) async {
    final sent = await _messaging.send(
      thread: _thread,
      author: _reader,
      body: body,
    );
    if (sent case Failed(:final failure)) {
      _emit(ThreadFailed(failure));
    }
  }

  /// Records that the reader has seen the thread.
  Future<void> markRead() async {
    final marked = await _messaging.markRead(
      thread: _thread,
      reader: _reader,
    );
    _emit(_settled(marked));
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  ThreadState _settled(Result<List<Message>, MessagingFailure> result) =>
      switch (result) {
        Success(:final value) => ThreadReady(value),
        Failed(:final failure) => ThreadFailed(failure),
      };

  void _emit(ThreadState next) {
    _state = next;
    notifyListeners();
  }
}
