import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';

import 'deliver_message.dart';

/// Tries again to send everything this device has written and not sent.
///
/// Called when a connection comes back. It answers with what actually left the
/// queue, so a caller can say "3 sent" rather than re-reading a thread to find
/// out.
///
/// **Oldest first, and a deferral stops the drain.** A thread is a
/// conversation: sending message four because message two hit a slow request
/// delivers an argument that reads backwards. The port promises the queue in
/// order, and this loop does not skip ahead.
///
/// **A refusal does not stop it.** The refused message will never go, so
/// stopping on it would block everything behind it for ever. It stays in the
/// queue for a person to see, and the drain carries on — which is exactly the
/// distinction `DeliveryDeferred` and `DeliveryRefused` exist to make, and the
/// reason `HttpMessageTransport` sorts a 4xx from a 5xx.
final class DrainQueue
    implements UseCase<(), Result<List<Message>, MessagingFailure>> {
  /// Creates the use case.
  const DrainQueue({required this._store, required this._deliver});

  final MessageStore _store;
  final DeliverMessage _deliver;

  @override
  Future<Result<List<Message>, MessagingFailure>> call(() input) async {
    final read = await _store.queued();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final sent = <Message>[];
    for (final message
        in (read as Success<List<Message>, MessagingFailure>).value) {
      final attempt = await _deliver(message);

      switch (attempt.failure) {
        case null:
          sent.add(attempt.message);
        case DeliveryRefused():
          continue;
        case _:
          return Success(sent);
      }
    }
    return Success(sent);
  }
}
