# shipments_testing

Fakes, fixtures and contract kits for shipments. Consumed by other packages' tests, never by production code.

## What it is for

| Type | Role |
|---|---|
| `InMemoryShipmentGateway` | a gateway that really stores, resolves and can be told to fail |
| `InMemoryShipmentCache` | the same for the cache port, where a miss is a success with `null` |
| `FakeBarcodeResolver` | a resolver backed by a map a test fills in |
| `ShipmentBuilder` | a shipment in any reachable state, built by walking the machine to it |
| `runShipmentGatewayContract` | one suite, run against every `ShipmentGateway` |
| `runShipmentCacheContract` | one suite, run against every `ShipmentCache` |

## The contract kit is the reason this package exists

A hand-written fake drifts. Nothing checks that "what the fake does" is still "what the real adapter does", so the two diverge quietly and the tests that trusted the fake go on passing while production breaks. The kit is the structural answer: one suite, called from here against the fakes and from `shipments_infrastructure` against `RestShipmentGateway`. If either side ever answers differently, one of the two runs goes red.

What belongs in it is only what is reachable **through the port**. Seeding happens through `save`, not through a back door, because a back door is something only one implementation has and the suite would stop being runnable against the other. Transport failures are not in it for the same reason — there is no way to provoke one through the port — so they stay in each implementation's own tests.

## The builder walks the machine

`ShipmentBuilder` never calls `Shipment`'s public constructor. That constructor can put a shipment into any state — mappers need it to rebuild one from a row — and a builder that used it could hand a test a shipment the machine cannot produce. Every assertion against such a fixture is an assertion about a situation that never happens.

Each step calls the transition it is named after and throws if the machine refuses, so a misconfigured fixture fails loudly in setup instead of quietly in an assertion. `shipment_builder_test.dart` asserts exactly that: `ShipmentBuilder().delivered().build()` throws.

Every step returns a *new* builder, so a shared prefix can be reused without one branch leaking into another.

## Why `test` is a runtime dependency here and not in `core_testing`

Because of what each package ships. `core_testing` ships fakes — plain classes with no matchers in them — so `package:test` belongs in its dev dependencies, and putting it anywhere else would drag the test harness into the dependency graph of everything that consumes a fake.

This package also ships a contract kit, and a contract kit *is* tests: it calls `group` and `test` from `lib/`. Leaving `test` in dev dependencies would be a `dev_dependency_in_lib` violation, and rightly so.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, `core_testing`, and other features' `_api` packages. The last of those was added to the constitution for this package: `shipments_api` names `ActorId` in its own public surface, and a fixture builder that could not write the type down would stop at the first cross-feature signature. See the note under §2.1 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md).

## What must never live here

- **Any implementation package.** A fake bound to `payments_application` would break whenever those use cases were refactored — which is the whole reason a contract package is separate from the code that satisfies it.
- **A mock.** These are fakes: they really store and really read back, so a test exercises the caller's logic rather than a script of expected calls.
- **A fake that cannot fail.** Failure is part of a port's contract; a fake that could not produce it would leave every caller's failure branch untested, and those are the branches that run on a bad day.
- **`DateTime.now()`.** `ShipmentBuilder.defaultMoment` is a constant, because a fixture whose timestamps move makes an equality assertion flake once a day.
