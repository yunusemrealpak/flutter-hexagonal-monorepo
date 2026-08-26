import 'dart:collection';

import 'package:core_kernel/core_kernel.dart';
import 'package:messaging_api/messaging_api.dart';

/// A [MessageTransport] the test drives.
///
/// Answers are a queue rather than a single value, so that a test can drive
/// the case this feature exists for: defer the first send, accept the second,
/// and assert that the message left the queue exactly once.
final class FakeMessageTransport implements MessageTransport {
  final Queue<Result<DateTime, MessagingFailure>> _answers = Queue();

  /// Every message this transport was asked to send, in order.
  final List<Message> sent = [];

  /// Every message a read receipt was sent for.
  final List<Message> acknowledged = [];

  /// The instant used when nothing is queued.
  DateTime acceptedAt = DateTime.utc(2026, 3, 4, 9, 15, 2);

  /// Queues an acceptance at [instant].
  void accept(DateTime instant) => _answers.add(Success(instant));

  /// Queues a failure.
  void refuse(MessagingFailure failure) => _answers.add(Failed(failure));

  @override
  Future<Result<DateTime, MessagingFailure>> send(Message message) async {
    sent.add(message);
    return _answers.isEmpty ? Success(acceptedAt) : _answers.removeFirst();
  }

  @override
  Future<Result<void, MessagingFailure>> acknowledgeRead(
    Message message,
  ) async {
    acknowledged.add(message);
    return const Success(null);
  }
}
