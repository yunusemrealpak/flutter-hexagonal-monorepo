import 'package:core_kernel/core_kernel.dart';
import 'package:notifications_api/notifications_api.dart';

/// The alert channel a desk has, which is none.
///
/// **This is an adapter in an app, and section 2 permits it on exactly one
/// row.** It is here rather than in `notifications_core` because it is not a
/// way of delivering alerts — it is this app's answer to a capability the
/// device does not have, and `notifications` has no business knowing that some
/// apps are desks.
///
/// It *declines* rather than pretending. `AlertsRefused` is a case the sealed
/// failure type already has, and `notifications_presentation` already renders
/// it as "alerts are off, turn them on to be told about work" — which is true
/// here and cannot be fixed here, so `InboxScreen.canRetry` draws no button.
/// A stub returning `Success` would have told a dispatcher their alerts were
/// on and then delivered nothing.
///
/// The inbox still works. A dispatcher reads what the operation has said by
/// opening the screen, which is what they were going to do anyway.
final class DeskAlertChannel implements AlertChannel {
  /// Creates the channel.
  const DeskAlertChannel();

  @override
  Future<Result<void, NotificationsFailure>> openFor(String actorId) async =>
      const Failed(AlertsRefused());

  @override
  Future<Result<void, NotificationsFailure>> closeFor(String actorId) async =>
      const Success(null);

  @override
  Stream<ArrivingAlert> arriving() => const Stream.empty();
}
