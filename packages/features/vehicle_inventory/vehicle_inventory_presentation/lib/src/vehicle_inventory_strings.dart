/// Every string key this package asks an app to answer.
abstract final class VehicleInventoryStrings {
  /// The count screen's title.
  static const String title = 'inventory.title';

  /// Shown before a count has been started.
  static const String idle = 'inventory.idle';

  /// Shown while the manifest is being fetched.
  static const String preparing = 'inventory.preparing';

  /// How far the count has got. Takes `scanned` and `expected` arguments.
  static const String progress = 'inventory.progress';

  /// How many parcels the manifest lists and the van does not have.
  ///
  /// Takes a `count` argument.
  static const String missing = 'inventory.missing';

  /// How many parcels the van has and the manifest does not list.
  ///
  /// Takes a `count` argument.
  static const String unexpected = 'inventory.unexpected';

  /// The count closed with nothing missing and nothing extra.
  static const String reconciled = 'inventory.reconciled';

  /// The load list could not be reached.
  static const String failureManifestUnavailable =
      'inventory.failure.manifestUnavailable';

  /// The count could not be saved.
  static const String failureCountUnavailable =
      'inventory.failure.countUnavailable';

  /// The count is no longer open.
  static const String failureCountMissing = 'inventory.failure.countMissing';

  /// The count is already finished.
  static const String failureCountClosed = 'inventory.failure.countClosed';

  /// The stored count could not be read.
  static const String failureMalformed = 'inventory.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    title,
    idle,
    preparing,
    progress,
    missing,
    unexpected,
    reconciled,
    failureManifestUnavailable,
    failureCountUnavailable,
    failureCountMissing,
    failureCountClosed,
    failureMalformed,
  ];
}
