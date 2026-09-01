import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// Stops alerts reaching this device.
///
/// Called on sign-out, and from the screen where somebody turns them off. A
/// device left open to a former courier's operation keeps buzzing with
/// somebody else's work, and the person holding it has no way to make it stop.
///
/// **The record is cleared only after the channel has closed.** If
/// unsubscribing failed, the device is still receiving; forgetting would
/// record a state it does not have, and the screen would then offer to open
/// what is already open.
final class CloseAlerts
    implements UseCase<String, Result<void, NotificationsFailure>> {
  /// Creates the use case.
  const CloseAlerts({required this._channel, required this._registry});

  final AlertChannel _channel;
  final AlertRegistry _registry;

  @override
  Future<Result<void, NotificationsFailure>> call(String actorId) async {
    final closed = await _channel.closeFor(actorId);
    if (closed case Failed()) {
      return closed;
    }
    return _registry.forget(actorId);
  }
}
