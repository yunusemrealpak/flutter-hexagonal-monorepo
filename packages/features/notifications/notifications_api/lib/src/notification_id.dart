import 'package:core_kernel/core_kernel.dart';

import 'notifications_failure.dart';

/// Identifies one entry in one inbox.
///
/// Wrapping a `String` is worth the ceremony here for the usual reason: an
/// inbox entry, a shipment and an actor are all strings on the wire and are
/// never interchangeable in a signature.
///
/// **Where the value comes from matters.** An alert that arrived as a push
/// carries the provider's message identifier, and push delivery is
/// at-least-once — the same message arrives twice on a flaky connection.
/// Reusing that identifier is what makes the second arrival a duplicate the
/// inbox can recognise rather than a second row a courier has to dismiss
/// twice. An alert with no provider identifier gets one from `IdGenerator`,
/// which is the only other way a caller is allowed to produce a value.
final class NotificationId extends ValueObject<String> {
  const NotificationId._(super.value);

  /// Reads a notification identifier from [raw].
  static Result<NotificationId, NotificationsFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedNotification(field: 'id', reason: 'it is empty'),
      );
    }
    return Success(NotificationId._(trimmed));
  }
}
