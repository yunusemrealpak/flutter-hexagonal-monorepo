/// Every string key this package asks an app to answer.
///
/// A presentation package writes keys and never sentences: section 2 of
/// docs/DEPENDENCY_RULES.md gives it `design_system` and no app, and the app
/// is the only package that knows which languages this product ships. The keys
/// are declared as constants rather than written inline so that an app can be
/// *checked* against them — `apps/*/test/catalogue_test.dart` walks [all] for
/// every feature it mounts and fails when one has no sentence behind it.
///
/// **[all] covers the keys this package asks for, not every key it can
/// display.** An `InboxEntry` carries a subject key chosen by whatever raised
/// the alert, and that set is data rather than source: it cannot be enumerated
/// here and the catalogue's own fallback is what answers it. The coverage test
/// is therefore a floor, not a proof.
abstract final class NotificationsStrings {
  /// The inbox screen's title.
  static const String inboxTitle = 'notifications.inbox.title';

  /// Shown when the read succeeded and the inbox was empty.
  static const String inboxEmpty = 'notifications.inbox.empty';

  /// The inbox could not be read.
  static const String failureUnavailable = 'notifications.failure.unavailable';

  /// The alert somebody opened is no longer there.
  static const String failureMissing = 'notifications.failure.missing';

  /// This person has turned alerts off.
  static const String failureRefused = 'notifications.failure.refused';

  /// The device has blocked alerts, and only its settings can unblock them.
  static const String failureBlocked = 'notifications.failure.blocked';

  /// The device could not be registered for alerts.
  static const String failureUnreachable = 'notifications.failure.unreachable';

  /// A stored alert could not be read.
  static const String failureMalformed = 'notifications.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    inboxTitle,
    inboxEmpty,
    failureUnavailable,
    failureMissing,
    failureRefused,
    failureBlocked,
    failureUnreachable,
    failureMalformed,
  ];
}
