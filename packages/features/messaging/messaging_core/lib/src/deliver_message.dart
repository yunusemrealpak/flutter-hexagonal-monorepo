import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:messaging_api/messaging_api.dart';

/// What one delivery attempt left behind: the message as it now stands, and
/// what stopped it if anything did.
///
/// A record rather than a `Result`, and the shape is the point. A `Result`
/// would force a caller to choose between the message and the failure, and
/// both callers here need both: the message is stored either way, and the
/// failure decides what happens to the *next* message in the queue.
typedef DeliveryAttempt = ({Message message, MessagingFailure? failure});

/// Sends one message and records what came back.
///
/// Shared by `SendMessage` and `DrainQueue`, which is the whole reason it is a
/// class of its own: the rule about what a deferral and a refusal mean has to
/// be identical on the first attempt and on the fiftieth. Two copies of it
/// would drift, and the drift would show up as a message that sends on retry
/// but not when it is written, or the reverse.
final class DeliverMessage {
  /// Creates the helper.
  const DeliverMessage({
    required this._store,
    required this._transport,
    required this._logger,
  });

  final MessageStore _store;
  final MessageTransport _transport;
  final Logger _logger;

  /// Tries to send [message].
  ///
  /// A successful send stores the message again with the server's instant on
  /// it — the store is the queue, so that write is what takes it out.
  ///
  /// A refusal is logged and the message is left queued. Silently dropping
  /// something somebody typed is the one behaviour a messaging feature must
  /// not have; a person can see it and delete it.
  Future<DeliveryAttempt> call(Message message) async {
    final sent = await _transport.send(message);

    switch (sent) {
      case Success(:final value):
        final acknowledged = message.sentAtInstant(value);
        final stored = await _store.put(acknowledged);
        return switch (stored) {
          // The server took it and the device could not write that down. The
          // message stays queued and will be sent again — which is safe,
          // because the identifier was minted before the first attempt and the
          // server recognises the second copy as the same message.
          Failed(:final failure) => (message: message, failure: failure),
          Success() => (message: acknowledged, failure: null),
        };
      case Failed(failure: DeliveryRefused(:final reason)):
        _logger.log(
          LogLevel.warning,
          'the operation refused ${message.id.value}: $reason',
        );
        return (
          message: message,
          failure: DeliveryRefused(reason: reason),
        );
      case Failed(:final failure):
        return (message: message, failure: failure);
    }
  }
}
