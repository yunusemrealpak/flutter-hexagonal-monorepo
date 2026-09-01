import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// Makes sure alerts reach this device, or says why they will not.
///
/// A thin use case, and deliberately one rather than a call the coordinator
/// makes on the port directly. The port belongs to a use case; the coordinator
/// composes use cases. Keeping that true when there was nothing to compose is
/// what made it obvious where the first rule goes — and the first rule has
/// arrived.
///
/// **The registry is written only after the channel has opened.** Firebase
/// exposes no way to read a device's topic subscriptions, so this flag is the
/// only record that the device asked to be reached; recording an open that did
/// not happen is how a switch ends up drawn on while nothing arrives.
///
/// A registry write that fails after a successful open is *reported*, not
/// swallowed. The device is subscribed and the application has no memory of
/// it, which is a state a caller has to be able to see — the alternative is a
/// courier whose alerts work and whose switch says they do not.
final class OpenAlerts
    implements UseCase<String, Result<void, NotificationsFailure>> {
  /// Creates the use case.
  const OpenAlerts({required this._channel, required this._registry});

  final AlertChannel _channel;
  final AlertRegistry _registry;

  @override
  Future<Result<void, NotificationsFailure>> call(String actorId) async {
    final opened = await _channel.openFor(actorId);
    if (opened case Failed()) {
      return opened;
    }
    return _registry.rememberOpen(actorId);
  }
}
