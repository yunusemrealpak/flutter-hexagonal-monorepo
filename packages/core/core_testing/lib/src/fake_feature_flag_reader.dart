import 'package:core_ports/core_ports.dart';

/// A [FeatureFlagReader] backed by a map.
///
/// An unknown key falls back to whatever the caller asked for, which is the
/// contract rather than a shortcut: the point of the required `orElse` is that
/// the caller decides what an unreachable flag service means, and this fake
/// has to honour that or it would test something the real adapter does not do.
final class FakeFeatureFlagReader implements FeatureFlagReader {
  /// Starts with [flags], empty by default.
  FakeFeatureFlagReader([Map<String, bool> flags = const {}])
    : _flags = Map<String, bool>.of(flags);

  final Map<String, bool> _flags;

  /// Sets [key] to [enabled], as a remote flag change would.
  void set(String key, {required bool enabled}) => _flags[key] = enabled;

  /// Removes [key], as an unreachable flag service would leave it.
  void remove(String key) => _flags.remove(key);

  @override
  bool isEnabled(String key, {required bool orElse}) => _flags[key] ?? orElse;
}
