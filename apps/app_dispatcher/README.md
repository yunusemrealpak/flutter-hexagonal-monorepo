# app_dispatcher

The operation's desk: online, single sign-on, and the second column of the adapter table in §5.5.

## What it may depend on

Anything — the `app` row in section 2 of [`docs/DEPENDENCY_RULES.md`](../../docs/DEPENDENCY_RULES.md) has no prohibitions.

**Ten features mounted, and only six overlap with `app_courier`.** `vehicle_inventory` and `documents` are a courier's — a van is counted by whoever stands next to it, and a waybill belongs to whoever carries the parcel. `reporting` and the dispatcher board are a desk's. Neither app compiles in what it does not mount.

## `delivery` is composed and none of it is mounted

`DeliveryFacade` resolves here, and `RemoteProofStore` is row 4 of the adapter table. No delivery route is in `dispatcherModules`, because a dispatcher reads an attempt and never stands at a door.

**A feature is a set of use cases and a set of destinations, and an app can want one without the other.** That is asserted in [`router_test.dart`](test/router_test.dart), and it produced a second finding on its own: this app's `.arb` carries *no delivery sentences*. Composing a feature is not the same as carrying its language, and a sentence for a screen nobody draws is a translation somebody maintains in every language forever. The catalogue coverage test checks that direction too, and it is what caught it.

## The adapter table, and the row that looks like a downgrade

| Port | Here | `app_courier` | Why they differ |
|---|---|---|---|
| `RouteOptimizerPort` | `RemoteSolverOptimizer` | `LocalHeuristicOptimizer` | a desk is online; a van is in a tunnel |
| `CredentialGateway` | `SsoCredentialGateway` | `DeviceBoundCredentialGateway` | a dispatcher signs in at whatever desk they are at |
| `OutboxStore` | `InMemoryOutboxStore` | `DriftOutboxStore` | see below |
| `ProofStorePort` | `RemoteProofStore` | `LocalEncryptedProofStore` | a copy of a signature on a desk is a second place it leaks |
| `PaymentsGateway` | `RestPaymentsGateway` | `RestPaymentsGateway` | money goes to one place however it was taken |
| `BarcodeResolverPort` | `RemoteBarcodeResolver` | `ManifestBarcodeResolver` | a depot scan may find a parcel on no manifest |
| `AlertChannel` | `DeskAlertChannel` | `FirebasePushMessagingClient` | see below |

**`InMemoryOutboxStore` is a choice, not an absence.** This app binds a database two registrations away — the key-value store is Drift, and `PeykDatabase` resolves. The queue is in memory because a dispatcher is online: their writes go out in the same second, and a queue that outlived a session would be one nobody drains and everybody inherits. The container test asserts *both* facts side by side, because "in memory" reads as a limitation until you see the database next to it.

It comes from `sync_testing`, and that is worth being uncomfortable about for a moment: a `_testing` package in a production app. The alternative is a second in-memory implementation in `sync_infrastructure` that differs from this one in nothing, and then two of them to keep in step with one contract kit. The specification's table names this class.

**`DeskAlertChannel` declines rather than pretending.** A desk has no push client, and `push_messaging` is not a dependency of this app. `NotificationsCoordinator` still takes an `AlertChannel`, so this app answers with an adapter that returns `AlertsRefused` — a case the sealed failure type already has, which `notifications_presentation` already renders as "alerts are off", and for which `InboxScreen.canRetry` already draws no button. A stub returning `Success` would have told a dispatcher their alerts were on and then delivered nothing.

It lives in `lib/src/di/` because it is not a way of delivering alerts. It is this app's answer to a capability the device does not have, and `notifications` has no business knowing that some apps are desks.

## Two ports a desk cannot honestly answer

Worth reading before copying this app's shape.

`RoutingCoordinator`'s constructor takes `RecalculateOnDeviation`, which takes a `LocationStreamPort`. `DeliveryCoordinator`'s takes `StartAttempt`, which takes a `GeoFencePort`. Both of those adapters read **this device's** position, and on a desk the only position available is the desk's. Recalculating a courier's route against it would be wrong.

They are bound anyway, and they are safe only because nothing on a dispatcher's screen calls those use cases. That is a runtime guarantee where the rest of this workspace has compile-time ones, and it is the honest state of the architecture rather than something to hide:

- **The seam is real.** A facade whose constructor demands every use case forces every app to bind every port, including ones its audience can never trigger.
- **The fix is not a rule change.** It is a `RemoteLocationStream` and a server-side geofence adapter, which are phase 8 work — or splitting the coordinators, which is a larger conversation about what a facade is for.
- **What phase 7 can do is stop it being invisible**, which is why it is named in the module's doc comments, in `DispatcherPlatform`'s, and here.

## The catalogue answers the same keys with different words

126 sentences in English and Turkish, against the keys ten presentation packages declare. `identity.failure.unavailable` is "No signal, try again in a moment" on a phone and "The identity service did not answer" at a desk on ethernet. `routing.title` is "Your route" there and "Courier route" here, because a dispatcher is never looking at their own.

**Neither is a translation of the other, and `identity_presentation` changed for neither.** That is what returning a key rather than a sentence bought, and it is only visible with two apps in front of you.

## `dispatcherUnmountedRoutes` mirrors the courier's

`routing.myRoute` is unmounted here and mounted there; `routing.courierRoute` is mounted here and unmounted there. One presentation package, two destinations, each app drawing the one its audience has a use for — the thing scenario 7 shows with two packages, shown here with one.

`payments.collect` is unmounted because a dispatcher does not take cash at a door; `payments` is composed all the same, for the status a board reads. `payments.refund` and `incidents.report` need forms nobody has written. `shipments.dispatcher.bulkAssign` is *not* in the set: it is the board reached through a wider permission, and a mode is not a second screen.

## Why this is a desktop app

It binds Drift and the keychain, which a browser has neither of. That is deliberate rather than careless: a dispatcher's desk runs macOS or Windows, and a web build would need a `KeyValueStore` and a `SecureStore` adapter this workspace has not written. Writing them silently against `dart:html` would have been the wrong kind of quiet.

## Code generation

`injectable_generator` over `lib/src/di/` — 103 registrations, with `throwOnMissingDependencies` on — and `flutter gen-l10n` into `lib/src/l10n/`. Both are §4.1's `apps/*` row, and both outputs are committed (§4.3).
