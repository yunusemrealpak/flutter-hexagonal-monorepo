/// The identity use cases. Pure Dart, and blind to every adapter that answers
/// its ports.
///
/// One class, and that is the honest shape of this feature: signing in,
/// signing out and refreshing are three operations over a single piece of
/// state, and separating them into three objects would mean three copies of
/// "the session right now". `IdentityCoordinator` therefore implements all
/// three of the ports identity publishes — `IdentityFacade` for the screens
/// that change the session, `SessionReader` and `PermissionChecker` for the
/// features that ask about it.
///
/// The rules are not here. `Session.needsRefreshAt` and
/// `Session.validateAgainst` live in `identity_api`, and this package calls
/// them. What belongs here is *when* to ask and *what to do* with the answer:
/// discard a session whose device tie has broken, log rather than fail when
/// the keychain is full, sign out locally even when the server cannot be told.
library;

export 'src/identity_coordinator.dart';
