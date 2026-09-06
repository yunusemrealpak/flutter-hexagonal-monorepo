import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

import 'messaging_fixtures.dart';

/// A [MessagingFacade] that really keeps threads.
///
/// For the packages that consume messaging without implementing it — a
/// presentation package's tests, and the harness app in phase 7. It behaves
/// the way the real coordinator does in the ways a caller can observe: a send
/// succeeds while the message is still queued, and marking read touches only
/// messages somebody else wrote.
final class FakeMessagingFacade implements MessagingFacade {
  final List<Message> _messages = [];
  final StreamController<ThreadId> _changes =
      StreamController<ThreadId>.broadcast();

  var _minted = 0;

  /// Whether a send leaves the message queued.
  ///
  /// The offline case is the one worth being able to force, because it is the
  /// one a screen renders differently.
  bool offline = false;

  /// Set to fail the next call.
  MessagingFailure? failNextWith;

  /// Held open by a test that needs two calls to overlap.
  ///
  /// This is the one way the fake is *less* faithful than the coordinator it
  /// stands in for: a real send crosses a network, and this one answers in the
  /// same microtask. A caller's concurrency policy — which of two sends
  /// arriving together is dropped, queued or restarted — is invisible against
  /// a facade that is never in flight, so a test asserting one has to be able
  /// to hold a call open.
  Completer<void>? gate;

  @override
  Future<Result<List<Message>, MessagingFailure>> read(ThreadId thread) async {
    if (gate case final gate?) {
      await gate.future;
    }

    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    return Success(
      _messages.where((m) => m.thread == thread).toList()
        ..sort((a, b) => a.writtenAt.compareTo(b.writtenAt)),
    );
  }

  @override
  Future<Result<Message, MessagingFailure>> send({
    required ThreadId thread,
    required ActorId author,
    required String body,
  }) async {
    if (gate case final gate?) {
      await gate.future;
    }

    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    _minted++;
    final written = Message.written(
      id: MessagingFixtures.id('FAKE-$_minted'),
      thread: thread,
      author: author,
      body: body,
      writtenAt: MessagingFixtures.written.add(Duration(minutes: _minted)),
    );
    if (written case Failed(:final failure)) {
      return Failed(failure);
    }

    final message = (written as Success<Message, MessagingFailure>).value;
    final stored = offline
        ? message
        : message.sentAtInstant(
            message.writtenAt.add(const Duration(seconds: 2)),
          );
    _messages.add(stored);
    _changes.add(thread);
    return Success(stored);
  }

  @override
  Future<Result<List<Message>, MessagingFailure>> markRead({
    required ThreadId thread,
    required ActorId reader,
  }) async {
    if (gate case final gate?) {
      await gate.future;
    }

    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }

    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.thread == thread && message.author != reader) {
        _messages[i] = message.readAtInstant(
          message.writtenAt.add(const Duration(minutes: 1)),
        );
      }
    }
    _changes.add(thread);
    return read(thread);
  }

  @override
  Stream<ThreadId> changes() => _changes.stream;

  /// Closes the change stream. Call from `addTearDown`.
  Future<void> dispose() => _changes.close();

  MessagingFailure? _taken() {
    final failure = failNextWith;
    failNextWith = null;
    return failure;
  }
}
