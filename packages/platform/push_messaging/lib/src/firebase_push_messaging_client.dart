import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'push_failure.dart';
import 'push_message.dart';
import 'push_message_mapper.dart';
import 'push_messaging_client.dart';

/// The [PushMessagingClient] the shipped applications run on.
///
/// Like the other device adapters here, it takes [PermissionRequester] through
/// its constructor rather than using the plugin's own `requestPermission`: one
/// mechanism for the whole app, and no `platform/*` -> `platform/*` edge to
/// `device_permissions`.
///
/// The incoming message stream is a constructor argument too, defaulting to
/// the plugin's. `FirebaseMessagingPlatform.onMessage` is a static
/// `StreamController`, which is the plugin's design and not something this
/// package can change — but reading it through an injected stream means the
/// adapter's tests never touch process-wide state, and a composition root can
/// substitute a replay of recorded pushes without patching a global.
final class FirebasePushMessagingClient implements PushMessagingClient {
  /// Registers through the given platform implementation, asking the given
  /// requester for access and stamping undated messages from the given clock.
  FirebasePushMessagingClient(
    this._platform,
    this._permissions,
    this._clock, {
    Stream<RemoteMessage>? incoming,
  }) : _incoming = incoming ?? FirebaseMessagingPlatform.onMessage.stream;

  final FirebaseMessagingPlatform _platform;
  final PermissionRequester _permissions;
  final Clock _clock;
  final Stream<RemoteMessage> _incoming;

  @override
  Future<Result<String, PushFailure>> currentToken() async {
    final blocked = await _blockedByPermission();
    if (blocked != null) {
      return Failed(blocked);
    }
    try {
      final token = await _platform.getToken();
      if (token == null) {
        // The provider answered without a token. Its own case because it is
        // the one worth retrying with backoff: a courier without a token
        // silently stops receiving assignments, and nothing about the device
        // looks wrong.
        return const Failed(
          PushRegistrationFailed(detail: 'the provider returned no token'),
        );
      }
      return Success(token);
    } on Object catch (error) {
      return Failed(PushRegistrationFailed(detail: error.toString()));
    }
  }

  @override
  Stream<String> tokenChanges() => _platform.onTokenRefresh;

  @override
  Stream<PushMessage> messages() =>
      _incoming.map((message) => toPushMessage(message, clock: _clock));

  @override
  Future<Result<void, PushFailure>> subscribeTo(String topic) =>
      _guard(() => _platform.subscribeToTopic(topic));

  @override
  Future<Result<void, PushFailure>> unsubscribeFrom(String topic) =>
      _guard(() => _platform.unsubscribeFromTopic(topic));

  Future<Result<void, PushFailure>> _guard(Future<void> Function() call) async {
    try {
      await call();
      return const Success(null);
    } on Object catch (error) {
      return Failed(PushUnavailable(detail: error.toString()));
    }
  }

  Future<PushFailure?> _blockedByPermission() async {
    var state = await _permissions.status(DevicePermission.notifications);
    if (state == PermissionState.notDetermined) {
      state = await _permissions.request(DevicePermission.notifications);
    }
    return switch (state) {
      PermissionState.granted => null,
      PermissionState.denied ||
      PermissionState.notDetermined => const PushPermissionDenied(),
      PermissionState.permanentlyDenied ||
      PermissionState.restricted => const PushPermissionBlocked(),
    };
  }
}
