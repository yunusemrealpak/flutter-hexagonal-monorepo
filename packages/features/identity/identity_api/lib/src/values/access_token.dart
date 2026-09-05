import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/identity_failure.dart';

/// A bearer token and the moment it stops being accepted.
///
/// Two fields, so it is not a `ValueObject<T>` — that base class wraps exactly
/// one. It is still a value: two tokens with the same text and the same expiry
/// are the same token, and [operator ==] says so.
///
/// It is hand-written rather than generated for one reason, and it is the
/// reason worth remembering about `freezed` in a package that holds secrets: a
/// generated `toString` prints every field. The first log line that
/// interpolated a `Session` would put a live bearer token into whatever
/// collects logs, and nobody would see it happen. [toString] here redacts.
@immutable
final class AccessToken {
  const AccessToken._({required this.value, required this.expiresAt});

  /// Reads a token issued by the credential gateway.
  ///
  /// [expiresAt] is passed in rather than computed, because computing it would
  /// mean calling `DateTime.now()` — forbidden by rule A1 — and because the
  /// expiry belongs to whoever issued the token, not to whoever parses it.
  static Result<AccessToken, IdentityFailure> issue({
    required String value,
    required DateTime expiresAt,
  }) {
    if (value.trim().isEmpty) {
      return const Failed(MalformedAccessToken('empty'));
    }
    if (!expiresAt.isUtc) {
      return const Failed(MalformedAccessToken('expiry is not UTC'));
    }
    return Success(AccessToken._(value: value, expiresAt: expiresAt));
  }

  /// The token text, as presented to the server.
  final String value;

  /// The instant, in UTC, from which the token is no longer accepted.
  ///
  /// UTC is enforced in [issue] rather than assumed. `Clock` promises UTC, and
  /// a local `DateTime` compared against a UTC one is off by the device's
  /// offset — a bug that only shows up for users in the wrong timezone.
  final DateTime expiresAt;

  /// Whether the token is already unusable at [now].
  ///
  /// The instant of expiry counts as expired: a token valid "until 12:00" is
  /// not valid at 12:00. The boundary has to be decided somewhere, and
  /// deciding it in the entity means the two callers that ask cannot disagree.
  bool hasExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// Whether the token expires within [threshold] of [now].
  ///
  /// This is the trigger for silent refresh. Refreshing on expiry instead
  /// would mean every request that happens to fall on the boundary fails once
  /// and is retried, which is a user-visible stall on a van with bad signal.
  bool needsRefreshAt(DateTime now, {required Duration threshold}) =>
      !now.add(threshold).isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessToken &&
          other.value == value &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(value, expiresAt);

  /// Prints the expiry and never the token.
  @override
  String toString() => 'AccessToken(expiresAt: $expiresAt)';
}
