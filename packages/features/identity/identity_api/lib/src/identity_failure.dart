import 'package:core_kernel/core_kernel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_token.dart';
import 'actor_id.dart';

part 'identity_failure.freezed.dart';

/// Everything that can go wrong on an identity port.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather than
/// in an adapter, because failing is part of a contract: the package that owns
/// the port owns what failing it means.
///
/// This is the shape code generation genuinely earns its place in. A failure
/// union is a closed set of small immutable values whose equality is
/// structural — two `MalformedActorId('')` values *are* the same failure — so
/// `freezed` generates exactly what would otherwise be written by hand, and
/// the hand-written version would drift the first time a case gained a field.
/// Entities are the opposite case and stay hand-written; the reasoning is in
/// this package's README.
///
/// The union extends [Failure] rather than implementing it, which `freezed`
/// supports because `Failure` is neither `base` nor `interface` and its only
/// constructor is a const one taking no arguments.
@freezed
sealed class IdentityFailure extends Failure with _$IdentityFailure {
  const IdentityFailure._();

  /// The identifier could not be read as an [ActorId].
  const factory IdentityFailure.malformedActorId(String raw) = MalformedActorId;

  /// The token could not be read as an [AccessToken].
  ///
  /// [reason] is for the log, not for the user: a bearer token that fails to
  /// parse is a bug in whatever issued it, and the person holding the phone
  /// can do nothing about it.
  const factory IdentityFailure.malformedAccessToken(String reason) =
      MalformedAccessToken;

  /// The credentials presented are not the credentials on file.
  ///
  /// Carries nothing on purpose. Whether the account exists, whether it was
  /// the password or the username that was wrong, and how many attempts
  /// remain are all answers that help an attacker more than a courier.
  const factory IdentityFailure.invalidCredentials() = InvalidCredentials;

  /// The account exists and the credentials matched, but it may not sign in.
  const factory IdentityFailure.actorDisabled(ActorId actorId) = ActorDisabled;

  /// There is no session to act on.
  ///
  /// Distinct from [SessionExpired]: nobody has signed in on this device, as
  /// opposed to somebody having signed in and the session having aged out.
  /// A caller routes the first to the sign-in screen and the second to a
  /// silent refresh, which is why collapsing them would cost a user their
  /// place in the app.
  const factory IdentityFailure.noSession() = NoSession;

  /// The session is past the point where it can be refreshed.
  const factory IdentityFailure.sessionExpired() = SessionExpired;

  /// This device is not one the actor's account is bound to.
  const factory IdentityFailure.deviceNotRegistered(String deviceId) =
      DeviceNotRegistered;

  /// The device is registered, but its fingerprint no longer matches the one
  /// the binding was issued against.
  ///
  /// The honest reading is a reinstall or an OS upgrade; the dangerous one is
  /// a copied token replayed from somewhere else. Neither can be told from the
  /// other here, so the session is invalidated and the actor signs in again.
  const factory IdentityFailure.deviceBindingBroken({
    required String deviceId,
    required String expectedFingerprint,
    required String actualFingerprint,
  }) = DeviceBindingBroken;

  /// The store or the remote end could not be reached, so nothing is known
  /// either way.
  ///
  /// Deliberately not merged with the failures above: "wrong password" and
  /// "could not ask" call for opposite behaviour in the caller, and the merge
  /// is how a network blip becomes a forced sign-out.
  const factory IdentityFailure.identityUnavailable({String? detail}) =
      IdentityUnavailable;
}
