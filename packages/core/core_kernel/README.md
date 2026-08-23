# core_kernel

The innermost ring of the architecture: the handful of types every other package in the workspace is allowed to share.

## What it is for

Six types, and nothing else:

| Type | What it is |
|---|---|
| `Result<S, F>` | The outcome of an operation that can fail. Sealed, with `Success` and `Failed`, plus `fold`, `map`, `flatMap` and `mapFailure`. |
| `Failure` | The base every domain failure extends. Deliberately empty — the cases and their payloads belong to the package that declares the port. |
| `ValueObject<T>` | A value defined entirely by what it holds. Supplies equality, hashing and printing; validation stays in a hand-written factory. |
| `Entity<TId>` | A domain object defined by its identifier, so it stays the same thing as its contents change. |
| `UseCase<TInput, TOutput>` | The shape of one product intention, with every collaborator arriving through the constructor. |
| `DomainEvent` | The base of everything published on the `DomainEventBus`. Requires `occurredAt`, which forces the caller to have asked a `Clock`. |

## What it may depend on

**Nothing.** Not the Flutter SDK, not one third-party package. Its `dependencies:` block is empty and stays that way.

Everything in the workspace is allowed to depend on `core_kernel`, so a dependency added here is a dependency added everywhere — and a rebuild here is a rebuild everywhere. That cost is what keeps this package small.

`dev_dependencies` carries `test` only. Nothing under `lib/` imports it, and it never ships; see [`docs/DEPENDENCY_RULES.md` §2.0](../../../docs/DEPENDENCY_RULES.md).

## What must never live here

- **Generated code.** There is no `build.yaml` and no `build_runner` dependency. Regeneration in the innermost ring would spread across the whole repository every time this package changed.
- **Any type that is not strictly needed.** The bar for adding one is that two unrelated rings both need it and neither can own it. Convenience helpers, extension methods on `Result` that a single feature wants, and "we might need this later" types all fail that bar.
- **Ports.** Ports declare a capability the outside world must provide; they live in `core_ports` or in a feature's `_api`. `core_kernel` describes shapes, not capabilities.
- **Anything that knows about a feature.** No `ShipmentId`, no `Money`, no domain vocabulary.

## Notes on two decisions

**`Failure` is empty.** A `message` getter was considered and rejected: it invites callers to render a failure rather than handle it, and the sealed subtypes already print usefully. A stable `code` string was rejected because every failure would have to invent one whether or not anything consumed it.

**`Result`'s failure type is unconstrained.** `Result<S, F>` does not require `F extends Failure`, so tooling and tests can use a plain `String`. In product code `F` is always a `sealed` `Failure` subtype declared by the package that owns the port.
