import 'package:core_kernel/core_kernel.dart';

import '../../entities/inbox_entry.dart';
import '../../failures/notifications_failure.dart';

/// Where one person's alerts are kept.
///
/// A driven port: `notifications_core` answers it, and an app decides whether
/// that answer is device storage, a remote mailbox, or a map in a test.
///
/// It takes a `String` actor identifier rather than an `ActorId`, for the
/// reason `docs/DEPENDENCY_RULES.md` §2.1 gives: a driven port whose signature
/// names another feature is a port its own adapter cannot implement without
/// depending on that feature.
abstract interface class InboxStore {
  /// Every alert for [actorId], newest first.
  ///
  /// An empty list is a successful read. An inbox with nothing in it is the
  /// state most inboxes are in.
  Future<Result<List<InboxEntry>, NotificationsFailure>> entriesFor(
    String actorId,
  );

  /// Stores [entry] for [actorId].
  ///
  /// **Idempotent by identifier.** Push delivery is at-least-once, so the same
  /// alert arrives twice on a flaky connection; an implementation that
  /// appended blindly would give a courier two rows to dismiss for one event.
  /// Storing an identifier that is already present leaves the stored entry
  /// alone — including its read mark, which the second arrival does not know
  /// about.
  Future<Result<void, NotificationsFailure>> put(
    String actorId,
    InboxEntry entry,
  );

  /// Replaces the entry with the same identifier.
  ///
  /// Fails with [NotificationMissing] when there is nothing to replace, which
  /// is the ordinary outcome of two devices reading one inbox: one clears an
  /// alert while the other still has the row on screen.
  Future<Result<void, NotificationsFailure>> update(
    String actorId,
    InboxEntry entry,
  );
}
