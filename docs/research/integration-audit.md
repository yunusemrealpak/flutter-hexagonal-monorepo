# What the workspace asks its dependencies for, and what it leaves on the table

**Status:** audited on 2026-09-01. Two findings fixed in the commits titled
`fix(analytics_otel): a tracer provider, so the adapters write somewhere` and
`fix(secure_store): a named keychain policy instead of an empty map`. The rest
are recorded here with evidence, and §6 says why two of them are not fixed.

**Why it was done:** the authorised-transport work found that Dio was
configured with no interceptors, no timeouts and no retry. The question that
followed was whether that was one oversight or a pattern. It is a pattern, but
not the one it looked like.

---

## 1. The shape of the finding

Every third-party integration in the workspace was read against what its
package offers. The adapters are, with few exceptions, **better than average**:
`ConnectivityMonitor` closes the subscribe-then-seed race with `Stream.multi`
and deduplicates on the mapped condition; `DevicePermissionRequester` earns the
`notDetermined` state the platform refuses to give it and keeps a durable ask
log; `PeykDatabase`'s migration history uses `TableMigration` for the one change
that rebuilds a table and `addColumn` for the ones that do not, and documents
the `from >= 2` hazard it hit.

The pattern is one layer up:

> **The adapter exposes a capability and nothing above it uses the capability.**

`KeychainSecureStore` made its options a required argument with no default —
and both composition roots answered `const {}`. `OutboxDao` wrote an atomic
increment and documented the race it prevents — and the use case does
read-modify-write instead. `PushMessagingClient` publishes `tokenChanges()` —
and nothing subscribes. `analytics_otel` implements two ports carefully — and no
tracer provider was ever registered, so everything it produced was discarded
inside the library.

That is the same defect the repository already names four times over — a
contract that is written, tested and never invoked. This audit found four more.

## 2. Fixed here

### 2.1 OpenTelemetry had no SDK behind it

`api.globalTracerProvider` answers `NoopTracerProvider` until
`registerGlobalTracerProvider` is called. Both applications read the getter
(`main.dart`, building the platform object) and neither called the registrar.
**Every span `OtelAnalyticsSink` started and every record `OtelLogger` wrote was
dropped inside OpenTelemetry**, with nothing failing and nothing logging to say
so. The test suite could not see it, because tests assert against
`RecordingLogger` rather than against a pipeline.

`PeykTelemetry.install` registers a `TracerProviderBase` with a
`BatchSpanProcessor`, a `Resource` carrying `service.name`, and —
finally — `ClockTimeProvider`, which had been written in phase 2 with only its
own tests as callers.

The ordering matters and the library enforces it: `registerGlobalTracerProvider`
throws once anything has *read* the getter, so `install` has to run before
`getTracer`. Its test proves the transition rather than the end state — it
asserts the span context is invalid before installing and valid after, because
that same `isValid` check is the branch `OtelLogger` takes to decide whether a
record joins an operation or becomes a detached span.

### 2.2 The keychain ran on whatever the native side defaults to

`KeychainSecureStore` takes `options` as a required argument with no default,
and its doc comment names the calls it expects. Both apps passed `const {}`.

`KeychainOptions` is a *named policy* rather than a default: nothing reads it
unless a composition root names it. It states the two things an empty map left
unsaid.

- **Apple: `first_unlock_this_device`.** The alternative classes migrate to a
  new device. The session is tied to a `DeviceBinding` the server checks, so a
  restored token fails a security check rather than working — but it is still a
  live bearer token sitting in somebody's backup until it expires.
  `unlocked_this_device` would be stricter and is the wrong trade: the outbox
  drains on a connectivity change, which happens with the screen off.
- **Android: `resetOnError: false`.** The default is `true`, which answers a
  decryption failure by wiping the store. That turns "the KeyStore is damaged"
  into "you were never signed in" — collapsing the two failures
  `IdentityFailure` keeps apart precisely so a caller can route one to sign-in
  and the other to a retry.

**A correction to the first draft of this audit.** It claimed Android was
falling back to unencrypted shared preferences for want of
`encryptedSharedPreferences: true`. That was true of plugin version 9; this
workspace is on 11, where AES-GCM under a KeyStore-wrapped key is the default
and the legacy mode is gone. The Android gap is `resetOnError`, and it is
smaller than the claim was.

## 3. Deferred, then closed — push was inert end to end

**Resolved on 2026-09-01.** The design is
[`docs/superpowers/specs/2026-09-01-alerts-opt-in-design.md`](../superpowers/specs/2026-09-01-alerts-opt-in-design.md);
what follows is the state that prompted it, kept because the reasoning for
*not* fixing it in this pass is the more useful half.

The audit's fourth headline was "token rotation has no subscriber". That is
true and it is not the problem. `PushAlertChannel` routes by **topic**, not by
token, so a rotated token is largely FCM's own problem to migrate.

The actual state is worse and simpler: **`NotificationsFacade.openAlertsFor` and
`closeAlertsFor` have no callers anywhere in the workspace.** Nothing subscribes
a courier to their alert topic on sign-in and nothing unsubscribes on sign-out.
`PushAlertChannel.openFor` — which is also the only code that requests the
notification permission — never runs. Push is inert from end to end, and the
deep-link entry work merged earlier can only ever be reached by a notification
the device was never registered to receive.

**It is not fixed here because the missing piece is a screen, not a wire**, and
the port says so itself: *"Called from a screen that has already explained why,
never on first launch."* Subscribing automatically on sign-in would prompt a
courier for notification permission with no explanation, spend the single iOS
prompt, and contradict the contract in writing. The app's established pattern
for every other permission is request-on-use — and alerts have no moment of use,
which is exactly why they need a screen the workspace does not have.

Adding a registration that could only ever *close* would be the same mistake
this document is about: a wire whose counterpart does not exist.

The decision needed is a product one: a notifications toggle in
`settings_presentation`, or a priming step in the sign-in flow.

### The outbox's three rows, closed together

They were one code path, and reading them together changed what the fix
was. Taken separately, two of them look like "call the method that exists":
`recordAttempt` was written and unused, and a transaction was missing. Taken
together they are the same defect — **the drain wrote whole rows from a
snapshot it read a network round trip ago** — and the method that existed
could not have been called, because it did not write `next_attempt_at` and a
drain needed two statements to express one decision.

The resolution put two *intents* on `OutboxStore` rather than a transaction:
`recordAttempt` and `accepted`. A `transaction(...)` method on the port would
have made every implementation offer a notion only one of them has, and would
have let a caller in `sync_application` — which may not name a database — open
one anyway.

The line that decides which pair of writes gets collapsed: **one fact or two.**
The server took the work and moved, so dropping the row and saving the cursor
is one method. On the conflict path the server's new position is worth keeping
whether or not the resolution that follows succeeds, so those stay two.

The race that this makes safe is not hypothetical and is not about isolates:
somebody resolving an entry on the review screen while the drain waits on the
request for it. The old write put the queued copy back with no reason on it,
and the next pass sent work a person had deliberately stopped.

Still open in this area, deliberately: whether to give up is decided from the
count the drain read rather than the one the store now holds. Correct while one
drain runs at a time; the thing to revisit when a background scheduler adds a
second.

### What the fix turned out to need

The toggle won, and building it found the thing this audit could not see from
the adapter side: **a switch needs a current value, and nothing in the workspace
could produce one.** `AlertChannel` could open alerts and close them and had no
way to report on them, and Firebase Messaging exposes no call that lists a
device's topic subscriptions. So the fix was not a screen over two existing
calls; it was a third fact the product had to start keeping — `AlertRegistry` —
reconciled on every read against a permission the operating system can revoke
without telling anybody.

That is worth adding to this document's own thesis. "The adapter exposes a
capability and nothing above it uses the capability" was accurate here and
incomplete: the two calls had no caller *and* the contract was missing the
third method a caller would have needed. A capability gap can hide a contract
gap, and the way to tell is to try to write the caller.

Two rows of §5's table went with it. `PermissionRequester.openSettings()` now
exists, because `AlertsBlocked` is a case distinct from `AlertsRefused`
precisely so that one of them can send somebody to the system settings — and
nothing could. Wiring it into the camera and location blocked paths is still
open.

## 4. Not fixed, and why — the background message handler

`FirebaseMessagingPlatform.onBackgroundMessage` is never set, so a data-only
push arriving while the app is terminated does nothing on Android.

This lands in the same category as `codemagic.yaml` and `fastlane/Fastfile`: it
is real, it matters, and **it cannot run in this repository as it stands**.
There is no `apps/*/android`, no Firebase initialisation and no
`google-services.json`; the handler runs in a separate isolate the container
never reaches, and it is invoked by native code that this workspace does not
build. A handler written now could not be exercised even by a test, because the
setter's only caller is the platform. It would be a contract with no invoker —
which is what §1 is about.

The step that closes it is the same one named in `docs/CI_CD.md` §7:
`flutter create --platforms=android,ios .` inside an app.

## 5. Everything else the audit found

Unfixed, with the evidence, ordered by what they cost.

| Finding | Evidence | Cost |
|---|---|---|
| ~~`OutboxDao.recordAttempt` has no caller~~ — **closed 2026-09-01** | `outbox_dao.dart`; `drain_outbox.dart` did `_store.put(entry.attempted(…))` | the read-modify-write race the DAO was written to prevent |
| ~~No `transaction()` anywhere~~ — **closed 2026-09-01** on the drain's accept path | `drain_outbox.dart` — `drop` then `saveCursor` | a kill between two writes loses the pairing |
| ~~No index on `outbox_entries`~~ — **closed 2026-09-01**, schema v5 | queried by `blocked_reason IS NULL`, ordered by `(created_at, id)` | full scan and sort on every drain of a day's offline work |
| `image_picker.getLostData()` unused | `image_picker_media_capture.dart` | Android can kill the app during capture; the photo is then recoverable only through it, and photos are this product's payload |
| Android background location has no foreground service | `geolocator_location_source.dart:77` passes a plain `LocationSettings` | `track(inBackground: true)` is in the contract; Android kills the stream within minutes |
| `Position.isMocked` is dropped | `GeoFix` does not carry it | mock location is the fraud vector for a delivery proof |
| ~~`openAppSettings()` unused~~ — port added 2026-09-01, wired into alerts only | `device_permissions` | `…PermissionBlocked` is produced in three packages; the alerts screen can now act on its one, camera and location still cannot |
| No `dispose:` on any registration | ~8 classes have `dispose()` | `IdentityCoordinator`'s stream controller and `ConnectivityMonitor`'s subscription outlive `container.reset()` |
| No go_router `errorBuilder`/`onException` | all three routers | entry is a URL from a push payload; an unmatched one shows the framework's error page |
| No router `observers` | all three routers | `AnalyticsSink.track` exists and nothing reports a screen view |
| drift `.watch()` unused | no reactive query in the workspace | `SyncFacade.statusChanges()` is fed by hand, so a write from elsewhere does not refresh the badge |
| No span wraps an operation | every span is zero-duration | `OtelLogger`'s active-span branch stays unreachable even now that a provider exists |
| `json_serializable` `checked: true` off | every `build.yaml` | a malformed field yields a `TypeError` naming no field instead of a `CheckedFromJsonException` naming one |
| `go_router_builder` is in CLAUDE.md §4.1 and is nobody's dependency | no pubspec lists it | the table describes a tool the workspace does not use; the fix is probably to delete the row, since §2.4 puts route construction in the app |

## 6. What the audit did not find

No integration was *wrong*. Nothing catches an exception it should let through,
nothing throws across a port, no adapter reaches for a plugin singleton, and no
technology contract has leaked upwards. The failures are all of the same kind —
a capability offered and not taken — which is a cheaper class of defect to carry
and a harder one to notice.

The reason it is harder to notice is worth stating: **every one of these passes
its own tests**, because a test constructs the adapter with the arguments the
test chooses. `const {}` is a valid options map. A no-op tracer provider records
nothing and reports success. The gap between "the adapter works" and "the
application uses it" is not visible from inside the package, and the place it
becomes visible is the composition root — which is the least-tested file in any
of these applications.
