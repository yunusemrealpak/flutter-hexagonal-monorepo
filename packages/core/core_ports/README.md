# core_ports

The capabilities a feature is allowed to ask the outside world for, declared as interfaces with no implementation.

## What it is for

Eleven ports, each one a thing the product needs and none of them a thing the product owns:

| Port | Returns | Why it is a port |
|---|---|---|
| `Clock` | plain value | so no line of product code calls `DateTime.now()` |
| `IdGenerator` | plain value | so a generated identifier is a value a test can choose |
| `RandomSource` | plain value | so retry jitter is assertable |
| `Logger` | void | so a pure Dart package never reaches for `print` or `debugPrint` |
| `NetworkStatus` | plain value / stream | so `sync` can decide whether attempting is worth it |
| `KeyValueStore` | `Result` | small durable values; disks fail |
| `SecureStore` | `Result` | secrets; keychains fail differently from disks |
| `AnalyticsSink` | void | analytics must never fail or slow a use case |
| `FeatureFlagReader` | plain value | an unreachable flag service answers with the caller's fallback |
| `DomainEventBus` | void / stream | so two features can react to each other without knowing each other |
| `PermissionRequester` | plain value | a denied permission is an outcome, not a failure |

Failure types for the two fallible ports — `StoreFailure` and `SecureStoreFailure` — are `sealed` and live here alongside them.

## What it may depend on

`core_kernel`, and nothing else.

## What must never live here

- **Implementations.** Not one. Adapters live in `packages/platform/*`; fakes live in `core_testing`.
- **A port only one feature needs.** The bar for this package is that more than one feature needs the capability and none of them owns it. A port used by `shipments` alone belongs in `shipments_api`, where its blast radius is one feature instead of the workspace.
- **Domain vocabulary.** No `ShipmentId`, no `Money`. These ports describe the machine, not the business.
- **Generated code.** Every port here is narrow enough to hand-write, so there is no `build_runner` dependency and no `build.yaml`.

## Two conventions this package establishes

**`Result` when it can fail, a plain value when it cannot.** `Clock.now()` has no failure mode; wrapping it would put an unreachable `Failed` branch at every call site and teach the wrong lesson about what `Result` is for. The prohibition on throwing across a port boundary still applies to every port without exception. See [`CLAUDE.md` §3](../../../CLAUDE.md).

**Keep the interface narrow, put the convenience in an extension.** `Logger` declares one method, so a fake or a real adapter has one thing to implement; the four severities developers actually type are extension methods on the port. The same trick applies anywhere ergonomics would otherwise widen a contract.
