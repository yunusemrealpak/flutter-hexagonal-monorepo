# identity_presentation

The identity UI: signing in, and the state a screen renders while it happens.

## It does not know how this app signs in

`SignInController` holds `IdentityFacade` and nothing else. `app_courier` binds a coordinator over `DeviceBoundCredentialGateway` — a handset, a password, then a device token — and `app_dispatcher` binds one over `SsoCredentialGateway`. This package is identical in both.

The credential kind is chosen by the caller, which is what keeps that true: a controller that built `PasswordCredentials` itself would be a controller the dispatcher app cannot use.

## Two decisions worth reading

**`InvalidCredentials` and `DeviceNotRegistered` render the same sentence.** Distinguishing them tells an attacker whether an account exists. The decision is made once, in `SignInScreen.describe`, at the only place that produces text — not in the failure type, where every caller would have to remember it. A test asserts the two messages are equal.

**A second submit while one is in flight is ignored.** Without that, a double tap on a slow connection sends two sign-ins, and the second one's session replaces the first's — including its device binding, which the two requests may not agree about.

## The only routes that need no session

`requiresSession: false` appears exactly once in the workspace, on `identity.signIn`, and that is what the flag is for: a sign-in screen behind a session guard is a screen nobody can ever reach.

## What it may depend on

Own `_api`, other features' `_api`, `core_kernel`, `core_navigation`, `design_system` (from phase 7), and the Flutter SDK.

## What must never live here

- **`identity_application` or `identity_infrastructure`.** Which gateway answers `CredentialGateway` is an app's decision, and this package must not be able to tell.
- **A secret in a state object.** `Credentials` redacts in `toString`; a controller that copied the password into its state would undo that.
- **A formatted message in a state object.** `SignInRejected` carries an `IdentityFailure`; the sentence is produced at the widget, where the locale is known.
- **`debugPrint`.** Rule A4.
