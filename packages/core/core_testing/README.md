# core_testing

Behavioural fakes for the `core_ports` capabilities.

## What it is for

Twelve fakes, one for every cross-cutting port plus the navigation contract:

| Fake | Stands in for | What makes it a fake and not a stub |
|---|---|---|
| `FakeClock` | `Clock` | time only moves when a test moves it; refuses to run backwards |
| `FakeIdGenerator` | `IdGenerator` | counts, or hands out a script; throws past the end of the script |
| `FakeRandomSource` | `RandomSource` | returns a scripted sequence and repeats it |
| `RecordingLogger` | `Logger` | keeps every record, filterable by severity |
| `FakeNetworkStatus` | `NetworkStatus` | real broadcast; repeats of the same condition emit nothing |
| `InMemoryKeyValueStore` | `KeyValueStore` | really stores and reads back; can be told to fail |
| `InMemorySecureStore` | `SecureStore` | same, with the failures only secure storage has |
| `RecordingAnalyticsSink` | `AnalyticsSink` | keeps every call, in order and in kind |
| `FakeFeatureFlagReader` | `FeatureFlagReader` | honours the caller's `orElse` for unknown keys |
| `RecordingEventBus` | `DomainEventBus` | really delivers *and* records |
| `FakePermissionRequester` | `PermissionRequester` | a permanently denied permission shows no prompt |

## What it may depend on

`core_kernel`, `core_ports` — and, when a fake needs it, `core_navigation`. Nothing here needs it today: the `Navigation` port these fakes stood in for was deleted, because a presentation package that navigates through a port is the design `DEPENDENCY_RULES.md` §2.4 rejects. The constitution permits the dependency; an unused one is still removed.

Note what is **not** in `dependencies`: `package:test`. The fakes are plain classes with no matchers, so the test harness stays a dev dependency. A `_testing` package that put `test` in `dependencies` would drag it into the dependency graph of everything that consumes a fake.

## What must never live here

- **Mocks.** No `when(...).thenReturn(...)`. A test written against a script of expected calls keeps passing when the caller is refactored into something wrong, and starts failing when the caller is refactored into something right.
- **Feature fakes.** A fake for `ShipmentGateway` belongs in `shipments_testing`. This package knows only the cross-cutting ports.
- **Contract test kits.** Those live in the `<feature>_testing` package that owns the port.
- **Anything Flutter.** Widget testing helpers belong with the presentation packages.

## Three things these fakes are built to make possible

**No test sleeps.** `FakeClock`, `FakeIdGenerator` and `FakeRandomSource` remove the three sources of ambient non-determinism. Between them they are why nothing in this workspace needs `Future.delayed` to test a timeout, a retry schedule, or an identifier.

**Failure branches are reachable.** `InMemoryKeyValueStore.failNextWith` and its secure-store counterpart queue failures, one per call. Failure is part of a port's contract, so the fake standing in for that contract has to be able to produce it — otherwise every caller's failure branch stays untested.

**Two application packages can be wired together in a test.** `RecordingEventBus` really delivers, so a test can subscribe `payments` to an event `delivery` publishes and assert on the reaction — with neither package depending on the other. That is scenario 2 of the architecture, testable before either feature exists.

## A bug this package's own tests caught

`FakeNetworkStatus.changes()` was first written as an `async*` generator that yielded the current condition and then forwarded the controller. An async generator does not subscribe to the underlying stream until after its first yield is delivered, so a test that subscribed and immediately drove a transition silently lost it. It now uses `Stream.multi`, whose callback runs synchronously on listen. A fake with a race in it is worse than no fake, because the tests it breaks look like bugs in the code under test.
