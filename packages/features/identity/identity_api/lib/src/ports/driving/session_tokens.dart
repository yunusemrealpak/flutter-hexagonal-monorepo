import 'package:core_kernel/core_kernel.dart';

import '../../failures/identity_failure.dart';
import '../../values/access_token.dart';
import 'identity_facade.dart';
import 'session_reader.dart';

/// What the outbound transport asks identity for.
///
/// A driving port, and a third one rather than two more methods on
/// [IdentityFacade], because §2.3 of `docs/DEPENDENCY_RULES.md` makes a
/// driving port one audience's conversation with the feature. The audience
/// here is the thing that authorises requests, and everything it can do is on
/// this interface: it presents a token, and after the server refuses one it
/// asks for another. It cannot sign anybody in, cannot sign anybody out, and
/// giving it a port that could would be handing the network layer the ability
/// to end a shift.
///
/// The counterpart port for *other features* is [SessionReader], and the
/// difference between them is the reason both exist. `shipments` wants to know
/// who is asking and never wants a token; a transport wants a token and has no
/// business knowing whose it is. One port serving both would give each of them
/// the other's half.
///
/// **Both methods return a token rather than a session.** The caller cannot
/// act on an actor, a role or a device binding, and a port that handed over
/// the whole session would let a header be built from a field that changes for
/// reasons authorisation has nothing to do with.
abstract interface class SessionTokens {
  /// The token to present on the next request.
  ///
  /// Refreshes first when the current one is close enough to expiry to be
  /// worth replacing — the rule is `Session.needsRefreshAt`, and this is the
  /// place the product acts on it. Refreshing on expiry instead means the
  /// first request after the boundary fails and is retried, which is a stall a
  /// courier feels on a bad connection.
  ///
  /// Fails with `NoSession` when nobody is signed in, which is an ordinary
  /// state rather than an error: an app on its sign-in screen is asking a
  /// question whose honest answer is "there is no token".
  Future<Result<AccessToken, IdentityFailure>> presentable();

  /// The token to present after the server refused the last one.
  ///
  /// Distinct from [presentable] because the two questions are different. The
  /// first asks what is current; this one asserts that what is current is not
  /// accepted, and so it refreshes whether or not the token looks due. An
  /// implementation that treated them the same would answer a 401 with the
  /// token that caused it.
  ///
  /// Fails with `SessionExpired` when the refresh window has closed, which is
  /// the signal to send the actor back to the sign-in screen.
  Future<Result<AccessToken, IdentityFailure>> renewed();
}
