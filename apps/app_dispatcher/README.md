# app_dispatcher

The operation's desk: online, single sign-on, and the second column of the adapter table in §5.5.

## What it may depend on

Anything — the `app` row in section 2 of [`docs/DEPENDENCY_RULES.md`](../../docs/DEPENDENCY_RULES.md) has no prohibitions.

**Ten features mounted, and only six overlap with `app_courier`.** `vehicle_inventory` and `documents` are a courier's — a van is counted by whoever stands next to it, and a waybill belongs to whoever carries the parcel. `reporting` and the dispatcher board are a desk's. Neither app compiles in what it does not mount.

## `delivery` is composed and none of it is mounted

`DeliverySettlement` and `DeliveryHistory` resolve here — not `DeliveryExecution` — and `RemoteProofStore` is row 4 of the adapter table. No delivery route is in `dispatcherModules`, because a dispatcher corrects and reads an attempt and never stands at a door.

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

## The two ports a desk could not answer, and the shape that demanded them

Worth reading before copying this app's shape, because the fix was not where the symptom was.

Until phase 8 this app bound a `LocationStreamPort` over the desk's own GPS and an `HttpGeoFence` that asked whether the desk was at a consignee's door. Neither could give a true answer, and both were bound anyway — because `RoutingFacade` and `DeliveryFacade` each declared every operation of their feature, and a coordinator implementing one took every use case behind it. An app that wanted `resequence` had to supply `RecalculateOnDeviation`; an app that wanted to read an attempt had to supply `StartAttempt`.

That is the Interface Segregation Principle at class level and the Common Reuse Principle at package level: a component must not force its users to depend on things they do not need, and here the dependency was transitive and visible in this app's `pubspec.yaml` as `location_service`.

Phase 7 recorded the seam as safe because no screen called those use cases. **That was wrong.** `RouteScreen` is mounted here at `routing.courierRoute`, its `initState` calls `RouteController.load`, and `load` called `recalculateOnDeviation` — because routing had no read-only "what is planned". Opening a courier's route from a desk read the desk's position and could replan that courier's afternoon from the office. It never fired only because this app's route cache is local and empty, which is an accident rather than a guarantee.

What replaced it:

- **One driving port per audience.** `RoutePlanning` / `RouteSupervision` / `RouteFollowing`, and `DeliveryExecution` / `DeliverySettlement` / `DeliveryHistory`. This app composes the ports a desk can answer and does not name the others.
- **Split constructors, not just split interfaces.** `IdentityCoordinator` implements three ports from one constructor, which segregates what a caller may ask but not what a composition root must supply. Routing and delivery needed both halves, so each has one coordinator per port and a shared channel for the change stream.
- **A query where a command was standing in.** `RoutePlanning.currentPlan` is what a screen opens on now, and `app_dispatcher` builds a `SupervisedRouteController` that has no way to reach the other one.

The result is in this app's dependency list: no `location_service`, no `geolocator_platform_interface`, and a `DispatcherPlatform` with five fields instead of six. The container test asserts the absence directly — `RouteFollowing` and `DeliveryExecution` are *not registered* — so the guarantee is checked rather than described.

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
