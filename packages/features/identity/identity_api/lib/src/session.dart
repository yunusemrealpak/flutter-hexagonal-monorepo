import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_token.dart';
import 'actor.dart';
import 'device_binding.dart';
import 'identity_failure.dart';

part 'session.freezed.dart';

/// One signed-in actor, on one device, holding one token.
///
/// A session is a value rather than an entity: refreshing does not mutate it,
/// it produces a new one, and two sessions carrying the same actor, token and
/// binding are the same session. That is why it is generated while [Actor] is
/// not.
///
/// The two business rules the specification names live here as [needsRefreshAt]
/// and [validateAgainst], not in a use case. A use case that owned them would
/// be the only place that knew them, and the presentation package that wants
/// to show "signing you back in…" would have to ask the use case to find out.
@freezed
abstract class Session with _$Session {
  /// Creates a session for [actor] on the device described by [deviceBinding].
  const factory Session({
    /// Who is signed in.
    required Actor actor,

    /// The bearer token requests are made with.
    required AccessToken accessToken,

    /// The device this session is tied to.
    required DeviceBinding deviceBinding,

    /// The instant, in UTC, past which the session can no longer be refreshed
    /// and the actor has to sign in again.
    ///
    /// Distinct from `accessToken.expiresAt`, and much later. The token is
    /// short-lived so that a leak is short-lived; the session is long-lived so
    /// that a courier is not asked for a password halfway through a shift.
    required DateTime refreshableUntil,
  }) = _Session;

  const Session._();

  /// How close to expiry the token is allowed to get before it is refreshed.
  ///
  /// A constant rather than a parameter because it is a property of the
  /// product, not of a call site: if two callers could pick different
  /// thresholds, the one that picked badly would be the one that produced the
  /// stall, and it would be a different one on every screen.
  static const Duration refreshThreshold = Duration(minutes: 5);

  /// Whether the token should be refreshed now.
  ///
  /// [now] is passed in rather than read, because reading it would mean
  /// `DateTime.now()` — rule A1 — and because a rule about time that reads the
  /// clock itself is a rule that can only be tested by waiting.
  bool needsRefreshAt(DateTime now) =>
      accessToken.needsRefreshAt(now, threshold: refreshThreshold);

  /// Whether a refresh is still possible at [now].
  bool canRefreshAt(DateTime now) => now.isBefore(refreshableUntil);

  /// Checks the session against the device it is being used on.
  ///
  /// Returns the session unchanged when it is usable, so that a caller can
  /// chain it with `flatMap` instead of branching. The two failures it can
  /// produce are the two the specification asks for: a session whose refresh
  /// window has closed, and a session whose device tie no longer holds.
  ///
  /// Order matters. The binding is checked first: a session presented on the
  /// wrong device is a security event whether or not it had also expired, and
  /// reporting it as a plain expiry would hide it in the noise of every
  /// ordinary sign-in.
  Result<Session, IdentityFailure> validateAgainst(
    DeviceBinding current,
    DateTime now,
  ) {
    if (!deviceBinding.matches(current)) {
      return Failed(
        DeviceBindingBroken(
          deviceId: current.deviceId,
          expectedFingerprint: deviceBinding.fingerprint,
          actualFingerprint: current.fingerprint,
        ),
      );
    }
    if (!canRefreshAt(now) && accessToken.hasExpiredAt(now)) {
      return const Failed(SessionExpired());
    }
    return Success(this);
  }
}
