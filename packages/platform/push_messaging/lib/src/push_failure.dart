import 'package:core_kernel/core_kernel.dart';

/// Why a push operation did not complete.
///
/// Receiving a message cannot fail — see `PushMessagingClient.messages` — so
/// these describe registration and topic management only.
sealed class PushFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const PushFailure();
}

/// The user has not granted notification permission, and can still be asked.
final class PushPermissionDenied extends PushFailure {
  /// Records that notifications were refused, with asking still possible.
  const PushPermissionDenied();

  @override
  String toString() => 'PushPermissionDenied()';
}

/// Notification permission is refused in a way the app cannot ask about again,
/// or device policy forbids it.
final class PushPermissionBlocked extends PushFailure {
  /// Records that notifications cannot be requested again from inside the app.
  const PushPermissionBlocked();

  @override
  String toString() => 'PushPermissionBlocked()';
}

/// The device could not be registered with the push provider.
///
/// Its own case rather than a general failure because it is the one a caller
/// should retry with backoff: a device that cannot register today usually can
/// tomorrow, and a courier without a token silently stops receiving
/// assignments.
final class PushRegistrationFailed extends PushFailure {
  /// Records that registration did not produce a token, with [detail] for the
  /// log.
  const PushRegistrationFailed({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'PushRegistrationFailed($detail)';
}

/// The provider failed for a reason none of the other cases describes.
final class PushUnavailable extends PushFailure {
  /// Records an unclassified failure, with [detail] for the log.
  const PushUnavailable({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'PushUnavailable($detail)';
}
