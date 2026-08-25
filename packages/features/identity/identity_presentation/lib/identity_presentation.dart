/// The identity UI: signing in, and the state a screen renders while it
/// happens.
///
/// `SignInController` holds `IdentityFacade` and nothing else. It does not
/// know whether this app signs in with a password or through a corporate
/// identity provider — `app_courier` binds a coordinator over
/// `DeviceBoundCredentialGateway`, `app_dispatcher` one over
/// `SsoCredentialGateway`, and this package is identical in both. The
/// credential kind is chosen by the caller, which is what keeps that true.
///
/// One decision worth reading is in `SignInScreen.describe`:
/// `InvalidCredentials` and `DeviceNotRegistered` render the same sentence.
/// Distinguishing them would tell an attacker whether an account exists, and
/// the decision is made once, at the only place that produces text.
library;

export 'src/identity_routes.dart';
export 'src/sign_in_controller.dart';
export 'src/sign_in_screen.dart';
export 'src/sign_in_state.dart';
