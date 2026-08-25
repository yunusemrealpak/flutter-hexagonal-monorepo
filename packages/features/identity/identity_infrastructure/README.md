# identity_infrastructure

The identity adapters: what answers its driven ports, the DTOs that cross the wire, and the mapper between them.

## What it is for

| Type | Answers | Over |
|---|---|---|
| `DeviceBoundCredentialGateway` | `CredentialGateway` | Peyk's own account directory |
| `SsoCredentialGateway` | `CredentialGateway` | a corporate identity provider |
| `SecureSessionStore` | `SessionStore` | the `SecureStore` port |
| `InstallationDeviceRegistry` | `DeviceRegistry` | the `KeyValueStore` port |

## Scenario 5, made concrete

Two adapters, one port. `app_courier` binds `DeviceBoundCredentialGateway` — a handset signs in with a password once and a device token afterwards. `app_dispatcher` binds `SsoCredentialGateway` — an operations desk signs in through the company's own login and never types a Peyk password.

`identity_application` does not change a line between them, and a test asserts that both produce the same `Session` from the same response body. Each also refuses the credentials it cannot serve *without sending anything*: an adapter that forwarded them would turn a configuration mistake into a network round trip and a message nobody can act on.

## Two stores, chosen apart

A session carries a live bearer token and belongs behind whatever the device calls a keychain. An installation identifier names a handset and authorises nothing — and putting *it* in the keychain would make it disappear on a passcode change, turning every such change into a device the operation no longer recognises.

That is why `core_ports` declares `SecureStore` and `KeyValueStore` separately, and why an adapter that treated them alike would either encrypt a theme or leave a token in plain text. It would be the second.

## Three failures that are not failures

`SecureSessionStore.read` returns `Success(null)` — signed out — for two cases that look like errors:

- **`SecureStoreKeyInvalidated`**, which is what a keychain says after a passcode change or a restore from backup. The bytes are gone for good; that is exactly a signed-out device. Reporting it as a failure would leave the app on an error screen it can never clear, and the user would have to reinstall to sign in again.
- **An entry that will not parse.** There is nothing a user can do about a corrupt keychain entry except sign in again, which is what returning `null` lets them do.

`SecureStoreUnavailable` stays a failure, because it is worth retrying — turning it into "signed out" would sign a courier out because the phone happened to be locked.

## The mapper drops an unknown role; `ShipmentMapper` refuses an unknown state

The two are deliberately opposite, and the direction is the whole reasoning. An unknown *shipment state* cannot be guessed at without risking a delivered parcel going back on somebody's manifest. An unknown *role* can only ever grant permissions this build also does not understand, so dropping it removes access rather than inventing it — and refusing the whole session instead would lock every courier out of an older app version the day a new role is added on the server.

Failing safe means different things in the two places, and a mapper that applied one rule to both would be wrong in one of them.

## The contract kit runs here

`adapters_test.dart` runs `runSessionStoreContract` against `SecureSessionStore` — the same suite `identity_testing` runs against its in-memory store. That is what stops the fake and the adapter it stands in for drifting apart.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, `platform/*`. Not another feature's `_api`, and not `identity_application`.

## What must never live here

- **A business rule.** `Session.needsRefreshAt` and `Session.validateAgainst` are in `identity_api`. An adapter that decided when to refresh would be a second, quietly diverging copy of the rule.
- **A thrown exception on any path out of a port method.** Invariant 1.2.9 — the `on FormatException` catches are the boundary, not defensive clutter.
- **A base URL, an API key, or a realm default.** They are configured by the composition root; a default would make the environment something a call site could get wrong.
- **`DateTime.now()`, `Uuid()`.** Rules A1 and A3. `InstallationDeviceRegistry` takes `Clock` and `IdGenerator` as ports, which is what lets a test assert the device identifier exactly instead of matching a wildcard.
