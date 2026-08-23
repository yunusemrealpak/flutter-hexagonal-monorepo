# http_dio

The workspace's HTTP transport contract, its Dio-backed adapter, and the fake that keeps the test suite off the network.

## What it is for

Three things, and nothing else:

| Type | Role |
|---|---|
| `HttpTransport` | the contract: send a request, get a `Result` back, never throw |
| `DioHttpTransport` | the only file in the workspace that imports Dio |
| `FakeHttpTransport` | a programmable transport, so no test opens a socket |

`HttpRequest`, `HttpResponse`, `HttpMethod` and the `sealed TransportFailure` hierarchy are the vocabulary those three share.

## Why the contract lives here and not in `core_ports`

`core_ports` holds capabilities the product asks for **in the product's own words** — a clock, a store, a permission. Nothing in the product asks for "an HTTP request". Features ask for a shipment or a payment, through ports declared in their own `_api` package, and a feature's `_infrastructure` answers that ask over one particular protocol.

So `HttpTransport` is a *technology* contract, and a technology contract belongs with the adapter that implements it. The layering that follows:

```
shipments_application  ->  ShipmentGateway        (port, domain words, shipments_api)
shipments_infrastructure -> HttpTransport         (contract, protocol words, here)
                         -> DioHttpTransport      (adapter, Dio words, here)
```

An `_application` package never reaches this library, and the dependency table is what stops it: `_application` may not depend on `platform/*` at all. A use case that could build an `HttpRequest` would eventually pick a retry policy, and a retry policy is not a business rule.

## What it may depend on

`core_kernel` for `Result` and `Failure`, and `dio`. Not `core_ports` — it implements none of those ports. Not another `platform/*` package, which the constitution forbids outright.

## What must never live here

- **A base URL, an API key, or an auth header.** They are configured on the `Dio` instance the composition root hands to the constructor. A default here would make the environment something a call site could get wrong.
- **Domain vocabulary.** No `ShipmentId`, no `Money`, no DTO for any feature's payload. A DTO belongs in the `_infrastructure` package that owns the endpoint.
- **A second adapter.** If a second transport is ever needed, it is a second `platform/*` package implementing the same contract — that is scenario 4 of the architecture, and it only works while this package stays one adapter deep.
- **A thrown exception on any path out of `send`.** Invariant 1.2.9. `DioHttpTransport` has an `on Object` catch for exactly this reason, and it is not defensive clutter: it is the boundary.

## Two decisions worth knowing about

**A non-2xx status is a failure, not a success with a bad number.** `TransportRejected` carries the whole response, because the body of a 4xx is where an API puts its reason and only the calling adapter can read it. The alternative — succeed on any answer and make every caller check the status — puts the same three-line check at every call site and gets skipped at one of them.

**Timeouts are their own case, and they carry the phase.** A connect timeout means nothing happened; a receive timeout means the server may well have processed the request. Anything retried after the second has to be idempotent, which is why `payments` binds its idempotency key to an intention rather than to an attempt.
