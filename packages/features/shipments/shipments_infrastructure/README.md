# shipments_infrastructure

The shipments adapters: what answers its driven ports, the DTOs that cross the wire, and the mappers between them.

## What it is for

| Type | Answers | Over |
|---|---|---|
| `RestShipmentGateway` | `ShipmentGateway` | `HttpTransport` from `platform/http_dio` |
| `KeyValueShipmentCache` | `ShipmentCache` | `KeyValueStore` from `core_ports` |
| `RemoteBarcodeResolver` | `BarcodeResolverPort` | the operation |
| `ManifestBarcodeResolver` | `BarcodeResolverPort` | what this device already holds |

The last two are one port with two adapters, chosen by an app's composition root — the small version of scenario 4. A scan on a desk should hit the source of truth; a scan in a warehouse doorway with no signal should still work, and the use case above them does not change a line either way.

This is the only package in the feature that knows shipments travel as JSON over HTTP. `shipments_application` may not depend on it — §2 forbids the edge outright — so a use case can never see an `HttpRequest` and can never end up owning a retry policy.

## The mapper is the boundary

`ShipmentMapper` is where invariant 1.2.10 is enforced: nothing above it sees a DTO, nothing below it sees an entity. It is hand-written, and that is the point. A generator turns JSON into a data class; it cannot decide that an absent `barcode` is `MalformedBarcode` rather than a `TypeError`, or that a status whose `kind` nobody recognises is a failure with the unknown value quoted in it. Those are decisions.

Two of them are worth naming:

- **An unknown state is refused, not guessed at.** Falling back to "awaiting assignment" would put a parcel the operation has already delivered back at the top of somebody's manifest.
- **One bad row fails the whole manifest.** A stop list that quietly omits a parcel is a parcel nobody delivers, and nobody finds out until the depot counts.

The mapper is also asymmetric on purpose: `toDomain` returns a `Result` and `toDto` does not. A `Shipment` cannot be invalid — the only ways to obtain one are a validating factory and a transition the state machine allowed — while what arrives from the wire is whatever the far side chose to send. That asymmetry is what a boundary looks like when it is doing its job.

## Failure translation

`TransportRejected(404)` becomes `ShipmentNotFound`; a timeout becomes `ShipmentsUnavailable` with the phase named. A caller of `ShipmentGateway` handles `ShipmentFailure` and must never see a transport failure: a status code is a fact about HTTP, and a use case that switched on one would stop compiling the day the API moves to gRPC.

`_tryDecode` is the one place this package catches, and it is not defensive clutter — it is the boundary. The alternative is letting a `FormatException` cross a port, which invariant 1.2.9 forbids and which would reach a use case with no way to handle it.

## Reading a courier without depending on identity

`shipments_api` declares `ShipmentStatus.assignedToCourier(ActorId)`, and this package may not depend on a foreign `_api` at all — §2, for a documented reason: an adapter that reaches another feature's concepts has taken on a use case's job.

The resolution is not to widen the rule. What this adapter needs is not identity's vocabulary but *shipments' answer* to "is this a courier we can name?", with a `ShipmentFailure` when it is not — and that answer belongs in `shipments_api`, as `CourierReference.parse` and `CourierReference.parseOptional`. The type stays inferred here and the rule stays enforced by the compiler: writing `ActorId` in this package would need an import that does not resolve.

## Why not drift

The specification puts persistence in `storage_drift`, and that is right for a feature that queries — a shipment history, a settlement report, anything with a `where` clause worth pushing down. This cache does two things: read one shipment by identifier, and list the ones on a courier, over a working set a courier can physically carry. A schema, a migration and a code generator for that would be machinery with nothing to do.

The moment the device needs a query the store cannot express, `KeyValueShipmentCache` is replaced by a drift-backed one and nothing above it changes. It is behind a port, and `runShipmentCacheContract` is what proves the replacement behaves the same.

## The contract kit runs here

`adapters_pass_the_contract_test.dart` runs the same two suites `shipments_testing` runs against its in-memory fakes — against `RestShipmentGateway` and `KeyValueShipmentCache`. That is what stops a fake and the adapter it stands in for from drifting apart.

The suite needs a transport that behaves like a server rather than a queue, so the test file carries a small in-memory one. It lives there rather than in `http_dio` on purpose: it knows the shipments API's paths, and a platform package that knew a feature's endpoints would have stopped being a platform package.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, `platform/*`. Not another feature's `_api`, and not `shipments_application`.

## What must never live here

- **A business rule.** The state machine is in `Shipment`. An adapter that decided what may follow what would be a second, quietly diverging copy of it.
- **A thrown exception on any path out of a port method.** Invariant 1.2.9.
- **A base URL, an API key, or an auth header.** They are configured on the transport an app's composition root supplies.
- **A DTO that reaches upwards.** If a `ShipmentDto` ever appears in a signature outside this package, the mapper has stopped being a boundary.
