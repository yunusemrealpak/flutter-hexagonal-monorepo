/// Supplies the credential the transport presents, and renews it once refused.
///
/// A *technology* contract, which is why it is declared here rather than in
/// `core_ports`: it speaks in the value of an `Authorization` header and in
/// what to do after a 401, and neither of those is a word the product uses.
/// The product's word is "session", it belongs to `identity`, and the adapter
/// that turns one into the other lives in `identity_infrastructure` — the one
/// package entitled to see both this contract and a session.
///
/// That indirection is not ceremony. §1.1 forbids a `platform/*` package from
/// depending on a feature, so this package cannot ask identity for a token; a
/// contract it declares and somebody else answers is the only shape left, and
/// it is the same shape `device_permissions` uses when it takes a
/// `KeyValueStore` it cannot construct.
///
/// **Neither method returns a `Result`.** The caller is an interceptor whose
/// only two moves are "attach a credential" and "do not", so a failure it
/// could not act on would become an unreachable branch — CLAUDE.md section 3.
/// `null` therefore covers every reason there is no credential: nobody is
/// signed in, the refresh window has closed, the store could not be read. The
/// adapter logs which one it was; the transport only needs to know that it has
/// nothing to present.
abstract interface class AuthorizationProvider {
  /// The credential to attach to the next request, or `null` when there is
  /// none.
  ///
  /// The complete header value — `Bearer eyJ…`, not the token alone — because
  /// the scheme is part of what the far side agreed to and an interceptor that
  /// prefixed one would be deciding a protocol detail on the provider's
  /// behalf.
  ///
  /// Implementations are expected to renew a credential that is *about* to
  /// expire before handing it over. Waiting for the 401 works, but it costs a
  /// failed round trip on a connection that may be the reason the app is slow
  /// in the first place.
  Future<String?> credential();

  /// The credential to try once more with after the server refused the last
  /// one, or `null` when no fresh credential can be obtained.
  ///
  /// Separate from [credential] because the two questions differ: the first
  /// asks what is current, this one asserts that what was current is not
  /// accepted. An implementation that treated them the same would answer a 401
  /// with the token that just caused it.
  ///
  /// Implementations must collapse concurrent calls onto one renewal. Ten
  /// requests in flight when a token expires produce ten 401s, and ten
  /// renewals would invalidate each other on any server that rotates refresh
  /// tokens.
  Future<String?> renewedCredential();
}
