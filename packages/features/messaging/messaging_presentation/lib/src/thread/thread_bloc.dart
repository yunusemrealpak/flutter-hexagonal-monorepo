import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

import 'thread_event.dart';
import 'thread_state.dart';

/// Drives one thread.
///
/// It holds one port — `MessagingFacade` — and no implementation. Whether the
/// message it sends went over the wire or into a queue is something this
/// package can only observe, never decide.
///
/// **`sequential()` on sending, and this is the one place in the migration
/// where dropping would be wrong for a reason of its own.** Two taps on the
/// collect button are the same payment; two messages typed quickly are two
/// different things somebody said, and they have to arrive in the order they
/// were written. `droppable()` would lose the second sentence of a two-line
/// answer, and `concurrent()` would let the second overtake the first.
///
/// **The subscription re-dispatches rather than reading.** `_onWatched` holds
/// the change stream with `emit.onEach` and, for a change to *this* thread,
/// adds [ThreadRequested] — so every read goes through one handler with one
/// `restartable()` policy, and a burst of changes collapses to one read of the
/// latest state rather than a queue of reads that can land out of order.
///
/// The filtering is here rather than in the facade because the facade
/// announces every thread that moves: one connection coming back drains
/// messages across several. Filtering here is what lets two thread screens
/// exist at once without either redrawing for the other's traffic.
final class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  /// Creates the bloc for one conversation.
  ThreadBloc({
    required this._messaging,
    required this._thread,
    required this._reader,
  }) : super(const ThreadIdle()) {
    on<ThreadRequested>(_onRequested, transformer: restartable());
    on<ThreadWatched>(_onWatched, transformer: restartable());
    on<MessageSent>(_onSent, transformer: sequential());
    on<ThreadMarkedRead>(_onMarkedRead, transformer: droppable());
  }

  final MessagingFacade _messaging;
  final ThreadId _thread;
  final ActorId _reader;

  Future<void> _onRequested(
    ThreadRequested event,
    Emitter<ThreadState> emit,
  ) async {
    if (state is ThreadIdle) {
      emit(const ThreadLoading());
    }
    emit(_settled(await _messaging.read(_thread)));
  }

  Future<void> _onWatched(ThreadWatched event, Emitter<ThreadState> emit) =>
      emit.onEach<ThreadId>(
        _messaging.changes(),
        onData: (thread) {
          if (thread == _thread) add(const ThreadRequested());
        },
      );

  /// Writes a message.
  ///
  /// Does not read afterwards: the facade announces the thread, and the
  /// subscription this bloc already holds does the reading. Reading here as
  /// well would read the thread twice for every message somebody types.
  Future<void> _onSent(MessageSent event, Emitter<ThreadState> emit) async {
    final sent = await _messaging.send(
      thread: _thread,
      author: _reader,
      body: event.body,
    );
    if (sent case Failed(:final failure)) {
      emit(ThreadFailed(failure));
    }
  }

  Future<void> _onMarkedRead(
    ThreadMarkedRead event,
    Emitter<ThreadState> emit,
  ) async {
    emit(
      _settled(await _messaging.markRead(thread: _thread, reader: _reader)),
    );
  }

  ThreadState _settled(Result<List<Message>, MessagingFailure> result) =>
      switch (result) {
        Success(:final value) => ThreadReady(value),
        Failed(:final failure) => ThreadFailed(failure),
      };
}
