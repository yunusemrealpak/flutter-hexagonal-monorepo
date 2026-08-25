/// An amount, in the smallest unit of its currency.
final class Money {
  /// Creates an amount.
  const Money(this.minorUnits);

  /// How many of them.
  final int minorUnits;
}
