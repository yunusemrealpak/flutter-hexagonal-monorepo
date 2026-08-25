import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import 'session_builder.dart';

/// A `CredentialGateway` that really authenticates, against a map.
///
/// Register the credentials it should accept, and it issues a session bound to
/// the device it was handed. Anything else is `InvalidCredentials` — the same
/// answer a real gateway gives, carrying nothing, because whether the account
/// exists helps an attacker more than a courier.
///
/// It also counts refreshes, because the rule the specification asks for —
/// refresh before the token expires — is only testable if something can say
/// whether a refresh happened.
final class FakeCredentialGateway implements CredentialGateway {
  final Map<Credentials, Session> _accepted = {};
  final List<IdentityFailure> _queuedFailures = [];

  /// Sessions this gateway has revoked, in order.
  final List<Session> revoked = [];

  /// How many times a refresh was asked for.
  int refreshCount = 0;

  /// Teaches the gateway that [credentials] belong to [session].
  ///
  /// When [session] is omitted, a default one is issued for whoever the
  /// credentials name.
  void accept(Credentials credentials, {Session? session}) {
    _accepted[credentials] =
        session ??
        SessionBuilder()
            .actor(credentials.actorId?.value ?? 'sso-actor')
            .build();
  }

  /// Makes the next call return [failure].
  void failNextWith(IdentityFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<Session, IdentityFailure>> authenticate({
    required Credentials credentials,
    required DeviceBinding binding,
  }) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final session = _accepted[credentials];
    if (session == null) return const Failed(InvalidCredentials());

    // The binding comes from the caller, so a fake that ignored it would let
    // a use case forget to pass the right one and no test would notice.
    return Success(session.copyWith(deviceBinding: binding));
  }

  @override
  Future<Result<Session, IdentityFailure>> refresh(Session session) async {
    refreshCount++;
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return AccessToken.issue(
      value: 'jwt.refreshed.$refreshCount',
      expiresAt: session.accessToken.expiresAt.add(const Duration(hours: 1)),
    ).map((token) => session.copyWith(accessToken: token));
  }

  @override
  Future<Result<void, IdentityFailure>> revoke(Session session) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    revoked.add(session);
    return const Success(null);
  }

  IdentityFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
