/// Every string key this package asks an app to answer.
abstract final class PaymentsStrings {
  /// The collection screen's title.
  static const String title = 'payments.title';

  /// Shown when nothing is owed on this parcel.
  ///
  /// Where this screen spends most of its life: most parcels are prepaid.
  static const String nothingOwed = 'payments.nothingOwed';

  /// What is owed. Takes `minorUnits`, `currency` and `scale` arguments.
  ///
  /// Three arguments rather than a formatted amount, because turning minor
  /// units into money needs a locale — where the separator goes, which side
  /// the symbol is on, whether there is a space. `scale` is the currency's own
  /// minor-unit digit count: a currency with three of them or none would break
  /// any formatter that assumed a hundred.
  static const String owed = 'payments.owed';

  /// What has been taken. Same arguments as [owed].
  static const String taken = 'payments.taken';

  /// The method currently selected. Takes a `method` argument.
  static const String takingBy = 'payments.takingBy';

  /// The cash option.
  static const String methodCash = 'payments.method.cash';

  /// The card option.
  static const String methodCard = 'payments.method.card';

  /// The action that records the payment.
  static const String collect = 'payments.collect';

  /// The label on the button that leaves a door the courier is finished with.
  static const String done = 'payments.done';

  /// The operation refused the collection. Takes a `reason` argument.
  static const String failureRefused = 'payments.failure.refused';

  /// The cash record could not be updated.
  static const String failureCashDrawerUnavailable =
      'payments.failure.cashDrawerUnavailable';

  /// The payment could not be recorded.
  static const String failureUnavailable = 'payments.failure.unavailable';

  /// The payment has already been taken.
  static const String failureAlreadySettled = 'payments.failure.alreadySettled';

  /// There is nothing to collect on this parcel.
  static const String failureNothingToCollect =
      'payments.failure.nothingToCollect';

  /// The refund is not possible. Takes a `reason` argument.
  static const String failureRefundNotPossible =
      'payments.failure.refundNotPossible';

  /// The day's total could not be read.
  static const String failureSettlementUnavailable =
      'payments.failure.settlementUnavailable';

  /// The day is already handed in.
  static const String failureSettlementClosed =
      'payments.failure.settlementClosed';

  /// The money is in the wrong currency.
  ///
  /// Takes `expected` and `actual` arguments.
  static const String failureCurrencyMismatch =
      'payments.failure.currencyMismatch';

  /// A stored value could not be read. Takes a `field` argument.
  static const String failureMalformed = 'payments.failure.malformed';

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    title,
    nothingOwed,
    owed,
    taken,
    takingBy,
    methodCash,
    methodCard,
    collect,
    done,
    failureRefused,
    failureCashDrawerUnavailable,
    failureUnavailable,
    failureAlreadySettled,
    failureNothingToCollect,
    failureRefundNotPossible,
    failureSettlementUnavailable,
    failureSettlementClosed,
    failureCurrencyMismatch,
    failureMalformed,
  ];
}
