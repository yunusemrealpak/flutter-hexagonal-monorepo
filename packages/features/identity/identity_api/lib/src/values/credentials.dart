import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import '../failures/identity_failure.dart';
import 'actor_id.dart';

/// What an actor presents in order to sign in.
///
/// Sealed and hand-written. Sealed, because the set of ways to authenticate is
/// closed and a gateway that handles all of them today should stop compiling
/// the day a fourth is added rather than fall through to a runtime error.
/// Hand-written, because every subclass carries a secret and `freezed` would
/// generate a `toString` that prints it — see the note on `AccessToken`.
///
/// The three cases are what makes scenario 5 of the architecture concrete:
/// `app_courier` binds a gateway that speaks [DeviceTokenCredentials],
/// `app_dispatcher` one that speaks [SsoAssertionCredentials], and both drive
/// the same use case.
sealed class Credentials {
  const Credentials();

  /// Who is signing in, where the credential names them.
  ///
  /// `null` for [SsoAssertionCredentials]: an assertion carries its own
  /// subject, and asking the caller to also state who they are invites the two
  /// to disagree.
  ActorId? get actorId;
}

/// A username and a password.
@immutable
final class PasswordCredentials extends Credentials {
  const PasswordCredentials._({required this.actorId, required this.secret});

  /// Reads password credentials, refusing the ones that cannot be right.
  ///
  /// The emptiness checks are here rather than on a screen so that every
  /// driving adapter gets them: a test harness that built credentials directly
  /// would otherwise be testing a path no real caller can reach.
  static Result<PasswordCredentials, IdentityFailure> create({
    required String actorId,
    required String secret,
  }) {
    if (secret.isEmpty) {
      return const Failed(InvalidCredentials());
    }
    return ActorId.parse(actorId).map(
      (id) => PasswordCredentials._(actorId: id, secret: secret),
    );
  }

  @override
  final ActorId actorId;

  /// The password, as typed.
  final String secret;

  /// Compares both fields, and is deliberately not constant-time.
  ///
  /// Nothing in this repository authenticates anybody: the comparison that
  /// decides a sign-in happens on a server, against a hash, and this one
  /// exists so that a fake gateway can recognise the credentials a test handed
  /// it. Writing a constant-time comparison here would imply a guarantee this
  /// class is not in a position to make.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordCredentials &&
          other.actorId == actorId &&
          other.secret == secret;

  @override
  int get hashCode => Object.hash(actorId, secret);

  @override
  String toString() => 'PasswordCredentials(${actorId.value}, <redacted>)';
}

/// A long-lived token issued to one device, used to sign in without typing.
@immutable
final class DeviceTokenCredentials extends Credentials {
  const DeviceTokenCredentials._({required this.actorId, required this.token});

  /// Reads device-token credentials.
  static Result<DeviceTokenCredentials, IdentityFailure> create({
    required String actorId,
    required String token,
  }) {
    if (token.isEmpty) {
      return const Failed(InvalidCredentials());
    }
    return ActorId.parse(actorId).map(
      (id) => DeviceTokenCredentials._(actorId: id, token: token),
    );
  }

  @override
  final ActorId actorId;

  /// The device token.
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceTokenCredentials &&
          other.actorId == actorId &&
          other.token == token;

  @override
  int get hashCode => Object.hash(actorId, token);

  @override
  String toString() => 'DeviceTokenCredentials(${actorId.value}, <redacted>)';
}

/// An assertion from a corporate identity provider.
@immutable
final class SsoAssertionCredentials extends Credentials {
  const SsoAssertionCredentials._(this.assertion);

  /// Reads an SSO assertion.
  static Result<SsoAssertionCredentials, IdentityFailure> create(
    String assertion,
  ) {
    if (assertion.isEmpty) {
      return const Failed(InvalidCredentials());
    }
    return Success(SsoAssertionCredentials._(assertion));
  }

  /// The encoded assertion, opaque to this package.
  final String assertion;

  /// Always `null`: the assertion names its own subject.
  @override
  ActorId? get actorId => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SsoAssertionCredentials && other.assertion == assertion;

  @override
  int get hashCode => assertion.hashCode;

  @override
  String toString() => 'SsoAssertionCredentials(<redacted>)';
}
