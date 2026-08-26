import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// Stops alerts reaching this device.
///
/// Called on sign-out. A device left open to a former courier's operation
/// keeps buzzing with somebody else's work, and the person holding it has no
/// way to make it stop.
final class CloseAlerts
    implements UseCase<String, Result<void, NotificationsFailure>> {
  /// Creates the use case.
  const CloseAlerts({required this._channel});

  final AlertChannel _channel;

  @override
  Future<Result<void, NotificationsFailure>> call(String actorId) =>
      _channel.closeFor(actorId);
}
