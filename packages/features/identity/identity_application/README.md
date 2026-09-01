# identity_application

The identity use cases. Pure Dart, and blind to every adapter that answers its ports.

## One class, and why

`IdentityCoordinator` implements four ports at once — `IdentityFacade`, `SessionReader`, `PermissionChecker` and `SessionTokens` — because all four are views of the same fact. The facade is what a screen calls to *change* the session; the next two are what other features ask *about* it; the last is what the outbound transport presents. Four objects would mean four answers to "which session is in force", and the first time they disagreed the request going out would be authorised as somebody the screens no longer show.

Splitting them across three objects would mean three copies of "the session right now", and the first time they disagreed a dispatcher would see a button their permissions no longer allow.

Signing in, signing out and refreshing are three operations over that single piece of state, so they are three methods rather than three use case classes. `shipments_application` splits because its use cases share nothing but ports; this one does not, because they share the state itself.

## The rules are not here

`Session.needsRefreshAt` and `Session.validateAgainst` live in `identity_api`. This package calls them. What belongs here is *when* to ask and *what to do* with the answer:

- **A stored session that no longer holds is discarded, not kept.** Keeping it would make the app look signed in until the first request, which is the worst possible moment to find out otherwise.
- **A full keychain does not stop a sign-in.** The session is usable for this run whether or not it survives a restart; failing there would turn a storage problem into an outage. Logged, not returned.
- **Sign-out succeeds locally even when the server cannot be told.** Sign-out is what a user reaches for when something is already wrong, and refusing it would strand them on the screen they are trying to leave.
- **`can` is `false` when nobody is signed in.** The safe direction, and the reason a caller never has to check for a session before checking for a permission.

## `restore` is not part of the facade

It is a lifecycle concern — the composition root calls it at start-up — rather than something a screen asks for. A screen wants to know whether anybody is signed in, and `sessionChanges` answers that.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, and other features' `_api` packages.

## What must never live here

- **The Flutter SDK.** Rule I2.
- **Any `_infrastructure` package, or any `platform/*`.** Which gateway answers `CredentialGateway` is an app's decision — a handset's directory in `app_courier`, a corporate provider in `app_dispatcher` — and this package must not be able to tell.
- **A service locator.** Every port arrives through the constructor.
- **`DateTime.now()`.** Rule A1. The clock is a port, which is why no test here waits for a token to expire.
