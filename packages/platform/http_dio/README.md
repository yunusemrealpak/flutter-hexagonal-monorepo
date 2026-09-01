# http_dio

The workspace's HTTP transport contract, its Dio-backed adapter, and the fake that keeps the test suite off the network.

## What it is for

Three things, and nothing else:

| Type | Role |
|---|---|
| `HttpTransport` | the contract: send a request, get a `Result` back, never throw |
| `DioHttpTransport` | the adapter |
| `FakeHttpTransport` | a programmable transport, so no test opens a socket |

`HttpRequest`, `HttpResponse`, `HttpMethod` and the `sealed TransportFailure` hierarchy are the vocabulary those three share.

Plus the chain that adapter runs under, which is the second half of the package and the reason this is the only package in the workspace that names Dio:

| Type | Role |
|---|---|
| `AuthorizationInterceptor` | attaches the credential, renews and replays once on a 401 |
| `AuthorizationProvider` | where the credential comes from — a contract, answered outside |
| `FakeAuthorizationProvider` | the fake for it, counting renewals |
| `RetryInterceptor` | sends an idempotent request again after a transient failure |
| `ObservabilityInterceptor` | one correlation identifier per call, and what became of it |
| `PeykTransport` | the timeouts, and the one order the chain runs in |

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

- **A base URL, an API key, or a credential's value.** The base URL is a required argument to `PeykTransport.optionsFor`, and a credential arrives at request time through `AuthorizationProvider`. A default for either here would make the environment something a call site could get wrong — and would put a secret in a package every feature depends on.
- **Domain vocabulary.** No `ShipmentId`, no `Money`, no DTO for any feature's payload. A DTO belongs in the `_infrastructure` package that owns the endpoint.
- **A second adapter.** If a second transport is ever needed, it is a second `platform/*` package implementing the same contract — that is scenario 4 of the architecture, and it only works while this package stays one adapter deep.
- **A thrown exception on any path out of `send`.** Invariant 1.2.9. `DioHttpTransport` has an `on Object` catch for exactly this reason, and it is not defensive clutter: it is the boundary.

## Two decisions worth knowing about

**A non-2xx status is a failure, not a success with a bad number.** `TransportRejected` carries the whole response, because the body of a 4xx is where an API puts its reason and only the calling adapter can read it. The alternative — succeed on any answer and make every caller check the status — puts the same three-line check at every call site and gets skipped at one of them.

**Timeouts are their own case, and they carry the phase.** A connect timeout means nothing happened; a receive timeout means the server may well have processed the request. Anything retried after the second has to be idempotent, which is why `payments` binds its idempotency key to an intention rather than to an attempt.


## The interceptors, and why they are here rather than anywhere else

Authorization, retry and correlation are properties of *every* outbound call. Put one of them in a gateway and it becomes one of thirty places to change a scheme; put one in a use case and a transport policy has become a business rule. The dependency table already forbids the second — `_application` may not see `platform/*` — so the only remaining question was where between a gateway and the socket they belong, and the contract had already answered it. `HttpRequest.headers` documents that *"the adapter adds its own — content type, authorization, tracing"*, and a decorator over `HttpTransport` would sit above the interface making that promise.

### How the credential gets here without this package seeing a feature

`AuthorizationProvider` is declared here and answered by `identity_infrastructure`, which §1.1 gives sight of both `platform/*` and its own `_api`:

```
IdentityCoordinator      implements SessionTokens         (identity_application)
BearerAuthorization      implements AuthorizationProvider  (identity_infrastructure)
AuthorizationInterceptor consumes   AuthorizationProvider  (here)
```

Nothing in this package knows what a session is, and nothing in `identity_application` knows what a header is.

### Three decisions worth not rediscovering

**A 401 is handled in `onResponse`, not in `onError`.** `DioHttpTransport` sends with `validateStatus: (_) => true` so that a 4xx keeps its body, so no status ever becomes a `DioException`. An implementation that put the refresh in `onError` compiles, passes a hand-written Dio test, and never fires in this workspace.

**`QueuedInterceptor` deadlocks for this job.** It looks like the answer to a token expiring under ten concurrent requests. It serialises response handling on one queue, and the replay's own response has to pass through that same queue while the handler awaiting the replay still holds it. Collapsing concurrent renewals belongs to the provider anyway — `IdentityCoordinator.refreshSession` does it — because "do not refresh a session twice at once" is a statement about the session.

**Only idempotent verbs are retried.** `TransportTimeout` carries its phase precisely because a receive timeout means the server may have processed the request. `RetryInterceptor` has no idempotency key, so it cannot make a `POST` safe; a feature that has one sets `RetryInterceptor.retryFlag` on the request it knows about.

## Two failure cases production could not reach

Both were live before `PeykTransport` existed, and both were invisible because every adapter dutifully translated a case that never arrived.

- **`TransportTimeout`.** Both applications built `Dio(BaseOptions(baseUrl: …))`, leaving `connectTimeout`, `sendTimeout` and `receiveTimeout` null — Dio's documented spelling of "wait forever". `PeykTransport.optionsFor` sets all three.
- **`TransportCancelled`.** Still unreachable, and deliberately: producing one needs a `CancelToken` on `HttpRequest`, and the caller who would cancel is a presentation package that may not see this library. It stays until something actually wants to cancel — a contract with no caller is the mistake this repository keeps finding.
