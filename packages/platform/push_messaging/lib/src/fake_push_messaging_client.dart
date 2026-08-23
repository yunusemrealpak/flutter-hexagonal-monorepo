import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'push_failure.dart';
import 'push_message.dart';
import 'push_messaging_client.dart';

/// A [PushMessagingClient] the test drives directly.
///
/// Push is the hardest thing in the product to observe on a real device — it
/// needs a server, a network and a physical handset — so a fake that can
/// deliver a message on demand is what makes the flows that *react* to a push
/// testable at all.
final class FakePushMessagingClient implements PushMessagingClient {
  /// Starts registered with [token], or unregistered when it is null.
  FakePushMessagingClient({this.token = 'fake-token'});

  /// The token [currentToken] answers with, or null for a device that has not
  /// registered.
  String? token;

  final StreamController<PushMessage> _messages =
      StreamController<PushMessage>.broadcast();
  final StreamController<String> _tokens = StreamController<String>.broadcast();

  /// Every topic currently subscribed to.
  final Set<String> topics = {};

  /// Makes the next fallible call return this failure.
  ///
  /// A field rather than a `failNextWith(...)` method: the fake has one knob
  /// and assigning to it reads as well as calling it.
  PushFailure? failNextWith;

  /// Delivers [message] to everyone listening.
  void deliver(PushMessage message) => _messages.add(message);

  /// Rotates the token, as the provider does on reinstall or restore.
  void rotateToken(String rotated) {
    token = rotated;
    _tokens.add(rotated);
  }

  /// Closes both streams.
  Future<void> dispose() async {
    await _messages.close();
    await _tokens.close();
  }

  @override
  Future<Result<String, PushFailure>> currentToken() async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    final current = token;
    if (current == null) {
      return const Failed(
        PushRegistrationFailed(detail: 'FakePushMessagingClient has no token'),
      );
    }
    return Success(current);
  }

  @override
  Stream<String> tokenChanges() => _tokens.stream;

  @override
  Stream<PushMessage> messages() => _messages.stream;

  @override
  Future<Result<void, PushFailure>> subscribeTo(String topic) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    topics.add(topic);
    return const Success(null);
  }

  @override
  Future<Result<void, PushFailure>> unsubscribeFrom(String topic) async {
    final failure = _takeFailure();
    if (failure != null) {
      return Failed(failure);
    }
    topics.remove(topic);
    return const Success(null);
  }

  PushFailure? _takeFailure() {
    final failure = failNextWith;
    failNextWith = null;
    return failure;
  }
}
