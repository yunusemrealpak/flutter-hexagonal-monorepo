/// Produces random values.
///
/// Randomness reaches product code in fewer places than time does, but the two
/// places it does reach matter: retry backoff jitter in `sync`, and any
/// sampling decision. Both are behaviour worth asserting on, and neither can
/// be asserted on while the numbers come from `Random()`.
abstract interface class RandomSource {
  /// A non-negative random integer strictly below [max].
  ///
  /// [max] must be positive.
  int nextInt(int max);

  /// A random double in the range 0.0 (inclusive) to 1.0 (exclusive).
  double nextDouble();
}
