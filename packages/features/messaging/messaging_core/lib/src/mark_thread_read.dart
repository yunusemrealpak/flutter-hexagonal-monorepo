import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:messaging_api/messaging_api.dart';

/// Which thread, and who has been reading it.
final class MarkThreadReadCommand {
  /// Creates the command.
  const MarkThreadReadCommand({required this.thread, required this.reader});

  /// Which conversation.
  final ThreadId thread;

  /// Who has seen it.
  final ActorId reader;
}

/// Records that somebody has read everything in a thread.
///
/// **It marks what other people wrote, never what the reader wrote.** A read
/// receipt on your own message means nothing, and producing one would show a
/// courier that the operation had read a message the operation has not seen.
///
/// **A queued message cannot be read**, and asking is not an error. Two
/// devices resynchronising in the wrong order produce exactly that, and
/// `Message.readAtInstant` refuses it silently rather than failing a call
/// nobody could act on.
///
/// The receipt goes to the operation for the newest message only. Telling the
/// server about each message separately would be one request per line of a
/// conversation, and the server already knows the thread's order.
final class MarkThreadRead
    implements
        UseCase<
          MarkThreadReadCommand,
          Result<List<Message>, MessagingFailure>
        > {
  /// Creates the use case.
  const MarkThreadRead({
    required this._store,
    required this._transport,
    required this._clock,
  });

  final MessageStore _store;
  final MessageTransport _transport;
  final Clock _clock;

  @override
  Future<Result<List<Message>, MessagingFailure>> call(
    MarkThreadReadCommand command,
  ) async {
    final read = await _store.thread(command.thread.value);
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final now = _clock.now();
    final thread = (read as Success<List<Message>, MessagingFailure>).value;
    final marked = <Message>[];

    for (final message in thread) {
      if (message.author == command.reader || message.isRead) {
        marked.add(message);
        continue;
      }

      final seen = message.readAtInstant(now);
      if (identical(seen, message)) {
        marked.add(message);
        continue;
      }

      final stored = await _store.put(seen);
      if (stored case Failed(:final failure)) {
        return Failed(failure);
      }
      marked.add(seen);
    }

    final newest = marked.where((m) => m.isRead);
    if (newest.isNotEmpty) {
      // The receipt is best-effort: the local record is what the courier sees,
      // and a receipt that could not be sent is not worth failing a read over.
      await _transport.acknowledgeRead(newest.last);
    }
    return Success(marked);
  }
}
