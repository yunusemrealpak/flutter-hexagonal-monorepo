import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// Makes sure alerts reach this device, or says why they will not.
///
/// A thin use case, and deliberately one rather than a call the coordinator
/// makes on the port directly. The port belongs to a use case; the coordinator
/// composes use cases. Keeping that true when there is nothing to compose is
/// what makes it obvious where the first rule goes — a retry policy, a check
/// that the actor is the signed-in one — instead of leaving it to be added to
/// a facade where no test looks for it.
final class OpenAlerts
    implements UseCase<String, Result<void, NotificationsFailure>> {
  /// Creates the use case.
  const OpenAlerts({required this._channel});

  final AlertChannel _channel;

  @override
  Future<Result<void, NotificationsFailure>> call(String actorId) =>
      _channel.openFor(actorId);
}
