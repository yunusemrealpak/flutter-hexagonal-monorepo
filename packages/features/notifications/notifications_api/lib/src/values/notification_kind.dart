import 'package:core_kernel/core_kernel.dart';

import '../failures/notifications_failure.dart';

/// What an alert is about, in the product's words.
///
/// **Not `PushMessageKind`.** That enum lives in `platform/push_messaging` and
/// is a technology's vocabulary — what a provider's payload said it was. This
/// one is the product's: an inbox entry is an assignment, a message, a route
/// change or an announcement whether it arrived by push, was written by a
/// dispatcher, or was produced by the app itself.
///
/// The two enums look almost the same today, and the day they stop is the day
/// this separation pays: a `routeUpdated` push that the product decides not to
/// show in the inbox is one line in a mapper rather than a change to a
/// contract three packages read.
enum NotificationKind {
  /// A shipment has been assigned to the person this inbox belongs to.
  assignment,

  /// Somebody at the operation has written to them.
  message,

  /// Their route has been recalculated.
  routeChange,

  /// Something the operation is telling everybody.
  announcement,

  /// Something this version of the product does not recognise.
  ///
  /// Never dropped and never an error, for the same reason
  /// `PushMessageKind.unknown` exists: a fleet updates over weeks, and an
  /// alert this version cannot classify is still an alert somebody should see.
  unrecognised;

  /// Reads a kind from its stored spelling.
  ///
  /// Fails rather than falling back to [unrecognised]. The caller is an
  /// adapter reading a record the product wrote itself, so a value that is not
  /// one of these means the record is corrupt — while [unrecognised] means the
  /// *outside world* sent something new, which is a different fact and is not
  /// a failure at all.
  static Result<NotificationKind, NotificationsFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedNotification(
        field: 'kind',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
