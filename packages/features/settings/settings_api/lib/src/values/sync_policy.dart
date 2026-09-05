import 'package:core_kernel/core_kernel.dart';

import '../failures/settings_failure.dart';

/// When this device may spend somebody's data allowance on synchronisation.
///
/// A courier's phone is often on a personal plan, and draining it is a real
/// complaint rather than a hypothetical one. The choice belongs to the person
/// holding the phone, which is why it is a preference and not a build flag.
///
/// What the policy does *not* decide is whether work is queued: an outbox
/// entry is written whatever this says. The policy governs when the queue is
/// allowed to drain, so choosing [manual] delays a hand-over report rather
/// than losing it.
enum SyncPolicy {
  /// Drain the queue on any connection.
  always,

  /// Drain the queue only on a connection that costs nothing to use.
  unmeteredOnly,

  /// Drain the queue only when somebody asks for it.
  manual;

  /// Reads a policy from its stored spelling.
  ///
  /// Fails rather than defaulting, for the reason given on
  /// `ThemePreference.parse`.
  static Result<SyncPolicy, SettingsFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedPreference(
        field: 'syncPolicy',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
