/// Every string key this package asks an app to answer.
///
/// Declared as constants so an app can be checked against them:
/// `apps/*/test/catalogue_test.dart` walks [all] for every feature it mounts
/// and fails when a key has no sentence behind it.
abstract final class SyncStrings {
  /// The review screen's title.
  static const String reviewTitle = 'sync.review.title';

  /// Shown when nothing in the queue needs a person.
  ///
  /// Not an error. This is the state the screen is in most of the time.
  static const String reviewEmpty = 'sync.review.empty';

  /// The action on a stuck entry.
  static const String reviewRetry = 'sync.review.retry';

  /// How many times an entry has been tried. Takes a `count` argument.
  static const String attempts = 'sync.review.attempts';

  /// Everything queued has been sent.
  static const String statusIdle = 'sync.status.idle';

  /// Work is being sent now. Takes a `count` argument.
  static const String statusDraining = 'sync.status.draining';

  /// Work is waiting for a network. Takes a `count` argument.
  static const String statusWaitingForNetwork = 'sync.status.waitingForNetwork';

  /// Work will be tried again shortly. Takes a `count` argument.
  static const String statusWaitingToRetry = 'sync.status.waitingToRetry';

  /// Work has been given up on and needs a person. Takes a `count` argument.
  static const String statusBlocked = 'sync.status.blocked';

  /// There is no network, so this list is whatever the device already had.
  static const String failureOffline = 'sync.failure.offline';

  /// The queue on this device could not be read.
  static const String failureOutboxUnavailable =
      'sync.failure.outboxUnavailable';

  /// Anything else sync can fail with.
  static const String failureOther = 'sync.failure.other';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    reviewTitle,
    reviewEmpty,
    reviewRetry,
    attempts,
    statusIdle,
    statusDraining,
    statusWaitingForNetwork,
    statusWaitingToRetry,
    statusBlocked,
    failureOffline,
    failureOutboxUnavailable,
    failureOther,
  ];
}
