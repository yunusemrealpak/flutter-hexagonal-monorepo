/// The currencies this operation takes money in.
///
/// An enum with a scale rather than a string code, because the scale is the
/// part that matters and a string carries none. Every amount in this feature
/// is held in minor units — kuruş, cents — and turning 1250 into "12,50" needs
/// to know that this currency has two of them. A currency with three (the
/// dinar) or none (the yen) breaks any code that assumed a hundred.
///
/// Deliberately short. A courier platform takes money in the currencies it
/// operates in, and a list of every ISO code would be a list nobody maintains.
enum Currency {
  /// Turkish lira.
  tryLira('TRY', 2),

  /// Euro.
  eur('EUR', 2),

  /// United States dollar.
  usd('USD', 2);

  const Currency(this.code, this.minorUnitDigits);

  /// The ISO 4217 code, for a wire or a receipt.
  final String code;

  /// How many decimal digits this currency's minor unit has.
  final int minorUnitDigits;

  /// Reads a currency from its ISO code, or `null` when it is not one taken
  /// here.
  ///
  /// Returns `null` rather than a `Result`, because the caller that has a
  /// string is always a mapper, and a mapper already has a failure type of its
  /// own to report with.
  static Currency? fromCode(String code) {
    for (final currency in values) {
      if (currency.code == code.toUpperCase()) return currency;
    }
    return null;
  }
}
