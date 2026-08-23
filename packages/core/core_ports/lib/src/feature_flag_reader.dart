/// Reads remotely controlled switches.
///
/// Reading a flag cannot fail: when the flag service is unreachable or the key
/// is unknown, the answer is the fallback the caller supplied. That is why
/// `orElse` is required rather than defaulted — the caller is the only party
/// that knows whether the safe answer for an unreachable service is on or off,
/// and a default of `false` would quietly make that decision for them.
abstract interface class FeatureFlagReader {
  /// Whether [key] is enabled, falling back to [orElse] when the flag is
  /// unknown or the source is unreachable.
  bool isEnabled(String key, {required bool orElse});
}
