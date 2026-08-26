import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

import 'deliver_message.dart';

/// What is being written, in which thread, by whom.
final class SendMessageCommand {
  /// Creates the command.
  const SendMessageCommand({
    required this.thread,
    required this.author,
    required this.body,
  });

  /// Which conversation.
  final ThreadId thread;

  /// Who is writing.
  final ActorId author;

  /// What they wrote.
  final String body;
}

/// Writes a message down, then tries to send it.
///
/// **It succeeds when the message is stored, not when it is sent.** A courier
/// in a tunnel has written the message; reporting a failure would make them
/// write it again and the operation would get it twice. What comes back is the
/// message — queued, if that is what it is — and the screen shows that.
///
/// The store is the queue, so "queued" costs no second write: the message is
/// stored once, and a successful send stores it again with the server's
/// instant on it.
///
/// The only thing that fails this use case is the *store*. A device that
/// cannot write the message down has genuinely lost it, and that is the one
/// case where telling somebody to try again is the right answer.
final class SendMessage
    implements UseCase<SendMessageCommand, Result<Message, MessagingFailure>> {
  /// Creates the use case.
  const SendMessage({
    required this._store,
    required this._deliver,
    required this._clock,
    required this._ids,
  });

  final MessageStore _store;
  final DeliverMessage _deliver;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<Message, MessagingFailure>> call(
    SendMessageCommand command,
  ) async {
    final built = MessageId.parse(_ids.newId()).flatMap(
      (id) => Message.written(
        id: id,
        thread: command.thread,
        author: command.author,
        body: command.body,
        writtenAt: _clock.now(),
      ),
    );
    if (built case Failed(:final failure)) {
      return Failed(failure);
    }

    final message = (built as Success<Message, MessagingFailure>).value;
    final stored = await _store.put(message);
    if (stored case Failed(:final failure)) {
      return Failed(failure);
    }

    final attempt = await _deliver(message);
    return Success(attempt.message);
  }
}
