# Entry from a notification: the row the navigation table said already existed

**Status:** decided on 2026-08-30. Implemented across the commits titled
`feat(push_messaging): a pressed notification is not a received one` and
`feat(app_courier): a pressed notification opens what it refers to`.

**Where the rule lives:** [`DEPENDENCY_RULES.md` §2.4](../DEPENDENCY_RULES.md),
unchanged. This is the row that section's own table marks *"Entry — deep link,
push payload, typed URL … already existed: yes"*. It existed as a contract and
had no caller; this is the caller.

---

## 1. What was missing

`RouteDefinition.path`, `redirectFor` and the `?from=` return-to-intended were
in place and tested. `push_messaging` delivered a payload. Nothing in the
workspace turned one into a location, so a courier who pressed a dispatcher's
message got the app's normal start screen and had to find the thread by hand.

Two things had to be decided, and only one of them was the mapping.

## 2. Receipt is not intent, and the contract could not say so

`PushMessagingClient` had `messages()`: pushes arriving while the app runs.
Navigating on that would be wrong — a courier is mid-signature, a push about a
route recalculation arrives, and the app takes them off the screen they chose
for something they have not read.

What entry needs is the *press*, and the provider distinguishes the two:
`onMessageOpenedApp` for a press that brought the app back from the background,
`getInitialMessage()` for a press that launched it from nothing. The contract
did not, so it grew:

| Member | Event | Why not one member |
|---|---|---|
| `messages()` | a push arrived | acting on it interrupts somebody |
| `openings()` | somebody pressed it | acting on it is what they asked for |
| `launchMessage()` | the press that started the app | it is waiting, not arriving |

**`launchMessage()` cannot be a stream and reading it consumes it.** The
provider hands the message over once, before anything could have subscribed,
and an app that read it twice would navigate to the same push again on its next
resume. `FakePushMessagingClient` consumes it too — a fake that kept answering
would let a test pass against behaviour the device will not repeat.

**It answers `null` rather than a `Result`.** Web and desktop do not implement
`getInitialMessage`. A launch this app cannot read about and a launch nobody
caused mean the same thing to a caller — start where the app normally starts —
so a failure branch there is one every call site writes and none can act on
differently. This is §3 of `CLAUDE.md`: a port returns `Result` when the
operation can fail *in a way the caller can act on*.

**`PushMessage` gained `shipmentId` and `threadId`.** The DTO already decoded
them and the mapper dropped them, so the app would have read
`data['thread_id']` — putting the wire spelling in a second place, when the
mapper's whole promise is that a server rename breaks exactly one map.

## 3. The mapping is a value, in the app, and its test checks the app mounted it

`CourierEntryPoints.forMessage` is a pure function to the same
`(route, parameters)` record `CourierFlow` produces. Entry and continuation
answer the same question about different events, and a second identical record
type would be two names for one shape.

It is in the app for the reason every route table is: route names are declared
in presentation packages, and `platform/*` may see neither a presentation
package nor a feature. A `PushMessageKind` cannot know a courier's app has a
manifest; a manifest cannot know push exists. The composition root is the only
place that knows both.

Its test is `CourierFlow`'s: every destination it can name is checked against
what the app mounted. A route name is a string, and this is what stops a
mistyped one being discovered by somebody who pressed a notification and landed
on nothing.

**Three answers are `null`, and each is a decision:**

- a kind this version does not recognise — a fleet updates over weeks, so a
  newer server must not be a crash on an older handset;
- a dispatch message that names no thread — guessing would open somebody
  else's conversation;
- a launch nobody caused.

All three are logged. None is an error.

`shipmentAssigned` opens the manifest rather than a detail screen: this app has
no screen for one shipment, and inventing a destination for the identifier
would be a route nobody wrote.

## 4. The test that pays for the whole design

```
no session
  ↓ courier presses a notification about thread shipment:SHP-1
router.goNamed('messaging.thread', {threadId: 'shipment:SHP-1'})
  ↓ redirectFor: requiresSession, no session
/sign-in?from=/threads/shipment%3ASHP-1
  ↓ session begins
ThreadScreen
```

Every arrow is a mechanism that already existed and had no caller entering from
outside the app. This is why entry stays a URL: a callback cannot be invoked by
a notification, and a callback would not pass through the guard, so a signed-out
tap would have had to be either dropped or handled a second way.

## 5. What was ruled out

- **Navigating on `messages()`.** §2. Receipt is not intent.
- **Reading `data['thread_id']` in the app.** §2. The wire spelling belongs to
  the package that owns the DTO.
- **A `Result` from `launchMessage()`.** §2. An unreachable failure branch at
  every call site.
- **Putting the mapping in `notifications_api`.** It would have to name routes
  from three other features, which is §2.1's `shared` package again — and
  `notifications` is a feature, not the audience.
- **A `PushEntry` in `app_dispatcher`.** A desk does not run on push presses;
  `DeskAlertChannel` already declines the capability. The shape is here if that
  changes.

## 6. What is still open

- **The scanned barcode and the pasted URL**, the other two entries §4.1 of the
  navigation note names. Both are URL entry and need no new mechanism —
  `shipments.courier.scan` is already mounted at `/stops/scan` — but nothing
  produces those URLs yet.
- **A notification that arrives while the app runs shows nothing.** `messages()`
  is deliberately not acted on, and an in-app banner is a design decision with
  no component behind it yet. `PeykBadge` on the inbox tab is the same
  conversation.
