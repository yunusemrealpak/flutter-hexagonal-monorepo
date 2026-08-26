import 'package:core_kernel/core_kernel.dart';

import 'message.dart';
import 'messaging_failure.dart';

/// Carries a message to the operation.
///
/// A driven port in the product's words — "carry this message" — answered by
/// an adapter that knows a protocol. It returns the instant the server took
/// the message rather than `void`, because that instant belongs to the server:
/// two devices in different time zones with drifting clocks would otherwise
/// each stamp their own, and a thread would sort differently on each of them.
abstract interface class MessageTransport {
  /// Sends [message] and answers with the instant the server accepted it.
  ///
  /// `DeliveryDeferred` means try again; `DeliveryRefused` means never. An
  /// adapter that collapsed the two would produce an outbox that either gives
  /// up on a tunnel or retries a closed thread for ever.
  Future<Result<DateTime, MessagingFailure>> send(Message message);

  /// Tells the operation that everything up to [message] has been read.
  Future<Result<void, MessagingFailure>> acknowledgeRead(Message message);
}
