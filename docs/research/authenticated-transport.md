# Authorising the outbound request: the seam that was missing, not misplaced

**Status:** decided on 2026-09-01. Implemented across the commits titled
`feat(http_dio): the interceptor chain the transport had no seam for`,
`feat(identity): the token the transport presents`, and
`feat(apps): every outbound request carries a credential`.

**Where the rule lives:** [`DEPENDENCY_RULES.md` §2.2](../DEPENDENCY_RULES.md)
and [§2.3](../DEPENDENCY_RULES.md), both unchanged. This work is those two
sections applied to a contract that runs in the *opposite* direction from every
other one in the workspace — declared by a `platform/*` package and answered by
a feature — and the fact that neither section needed amending is the argument
that the shape was already right.

---

## 1. What was missing

`RestShipmentGateway`, `RestPaymentsGateway`, `RemoteProofStore`,
`RemoteSolverOptimizer`, `HttpCommandTransport`, `HttpDocumentRenderer`,
`HttpManifestSource` and `HttpMessageTransport` all sent
`HttpRequest(method:, path:)` with no headers. `HttpRequest.headers`' own doc
comment said *"the adapter adds its own — content type, authorization,
tracing"*, and `DioHttpTransport` added none of the three. Against a real
backend, every request outside identity's own two gateways is a 401.

Two smaller holes sat next to it and were caused by the same absence:

- **`IdentityCoordinator.refreshIfDue()` had no caller.** The fourth instance
  of the pattern this repository keeps finding — after `IdentityFacade.signOut`,
  `SyncFacade.drain` and `core_navigation`'s `Navigation`. A token therefore
  expired and nothing was arranged to notice.
- **`TransportTimeout` could not be produced.** Both applications built
  `Dio(BaseOptions(baseUrl: …))`, which leaves `connectTimeout`, `sendTimeout`
  and `receiveTimeout` null — Dio's documented spelling of "no timeout at all".
  Eight adapters translated a case the workspace could not reach.

The three are one piece of work because they share one answer: nothing in the
workspace configured the client, so nothing in the workspace could add anything
to a request.

## 2. Above or below `HttpTransport`

The two candidates were a decorator implementing `HttpTransport` and wrapping
another, composed in each app; and a Dio interceptor inside `http_dio`. Both
can attach a header and both can replay a 401, so the choice is not about
capability.

It is settled by what the contract already promises. `HttpRequest.headers`
tells its callers that *the adapter* adds the authorization header, and
`http_dio`'s README has said since phase 2 that "the base URL, the auth header
and the retry policy are the adapter's business, not the caller's". A decorator
sits **above** `HttpTransport` — it is a caller — so it would satisfy the
promise from the wrong side of the interface that makes it, and the next person
to read `HttpRequest` would look one layer too low for the code.

Two smaller things fell the same way:

- **The replay.** A decorator that retried a refused request would hand the
  gateway's own mapping a second response to decode. An interceptor replays the
  request Dio already built, so the gateway sees exactly one outcome.
- **The duplication.** A decorator composed in each app is one copy per
  application of a rule neither application decides anything about. The
  precedent for per-app copies — `SessionRefresh`, `SyncOrchestrator`,
  `PushEntry` — is about *joining* things an app knows; this is a policy an app
  only turns on.

## 3. The credential crosses two contracts, and neither is a new kind

`platform/*` may not depend on a feature, so `http_dio` cannot ask identity for
a token. The chain that results looks longer than the handoff note's "one file"
estimate, and each link is a rule already written down:

| Package | Declares | Implements | Why it may |
|---|---|---|---|
| `identity_api` | `SessionTokens` | — | a driving port is one audience's conversation (§2.3) |
| `identity_application` | — | `SessionTokens` | the coordinator is the one thing that knows the current session |
| `http_dio` | `AuthorizationProvider` | — | a technology contract lives with its adapter (§2.2) |
| `identity_infrastructure` | — | `AuthorizationProvider` | the only row in §1.1 that sees both `platform/*` and a session |

Two contracts rather than one because they speak different languages. `SessionTokens`
answers in `AccessToken` and `IdentityFailure`; `AuthorizationProvider` answers
in the value of an HTTP header, and in `null` for every reason there isn't one.
Collapsing them would mean either identity naming a header or the transport
naming a session.

### Why `core_ports` was wrong for it

The obvious shortcut is a token port in `core_ports`, which `platform/*` may
already depend on. It fails that package's own bar for entry — *more than one
feature needs it and none of them owns it*. Identity owns the token outright.
The bar exists to stop `core_ports` becoming §2.1's forbidden `shared` package,
and a credential is exactly the kind of thing that would start it.

### Why `SessionTokens` is not two more methods on `IdentityFacade`

§2.3: a driving port is one audience's conversation with the feature. The
audience here authorises requests. Everything it can do is present a token and
ask for another; it cannot sign anybody in and must not be able to sign anybody
out. `IdentityCoordinator` implements the fourth port from the same constructor,
which §2.3 permits explicitly — separate interfaces limit what a caller may
*ask*, and the split into separate objects is only owed when some application
cannot supply one of them.

## 4. What the interceptors turned out to require

Three findings that a design sketch would not have produced.

**A 401 never reaches `onError`.** `DioHttpTransport` sends with
`validateStatus: (_) => true` so that a 4xx keeps its body — a decision from
phase 2, made for a completely different reason. The consequence is that no
status becomes a `DioException`, so refresh-on-401 has to live in `onResponse`.
The natural implementation, and every Dio tutorial, puts it in `onError`; here
it would compile, pass a hand-written test against a default client, and never
fire.

**`QueuedInterceptor` deadlocks.** It is Dio's own answer to "ten requests are
in flight when the token expires", and it has three task queues — request,
response and error. The replay is issued from an `onResponse` handler and its
own response has to pass through the *response* queue, which the handler
awaiting it still occupies. Nothing times it out; the request simply never
completes. Reading the source was faster than debugging it, and the lesson is
that a package's own concurrency helper is still a helper for a shape, not for
a problem.

**The collapse belongs to identity, not to the transport.** Once queuing was
out, the question "who stops ten 401s becoming ten refreshes" had a better
answer than it did before: `IdentityCoordinator.refreshSession` holds the
in-flight future. A server that rotates refresh tokens invalidates the other
nine, so the last one wins and nine sessions die — and that sentence is about
the session, not about HTTP. `AuthorizationProvider` requires the collapse in
writing so that a future second implementation cannot forget it.

## 5. Telling identity's own requests apart, without a path list

The interceptor must not authorise `/sessions`, and must not answer a 401 from
`/sessions/refresh` by refreshing. A list of paths here would make `http_dio`
know identity's URL layout — precisely the dependency §1.1 forbids.

The rule is about the request instead, and it is two flags on
`RequestOptions.extra`:

- **A request that already carries `Authorization` is left alone.** That is
  identity refreshing or revoking; the credential it holds is the only one that
  endpoint accepts, and overwriting it with the access token that just expired
  would break the one call able to fix the expiry.
- **A 401 is only worth renewing over when the interceptor attached the
  credential itself.** The presence of the header cannot answer that, because a
  replay sets the header too — so `attachedFlag` records the authorship and
  `replayedFlag` records the attempt.

Sign-in needs no special case at all: there is no session, so the provider
answers `null` and nothing is attached.

## 6. What was ruled out

**Dio's `LogInterceptor`.** It prints headers by default, and one of them is a
live bearer token. `AccessToken.toString` redacts for exactly this reason one
layer up, and the only defence that works against a log line is not building
it. `ObservabilityInterceptor` records the verb, the path, the status, the
duration and the correlation identifier, and nothing else — no header, no body,
no query value.

**Retrying anything non-idempotent.** `TransportTimeout` carries its phase
because a receive timeout means the server may well have processed the request.
`payments` binds an idempotency key to an *intention* rather than to an attempt,
which is what would make a retried `POST` safe — and that key is the feature's
knowledge. `RetryInterceptor.retryFlag` is the opt-in for a caller that has one;
nothing sets it today.

**Fixed backoff.** Every device that failed at the same moment would return at
the same moment. The delay is exponential with equal jitter, drawn through
`RandomSource` — rule A2, and the reason the schedule is an exact value in a
test rather than a range.

**A `traceparent` header.** `X-Request-Id` is one identifier for one call. The
W3C header means a trace context, and claiming it would mislead whatever
collects it.

## 7. What is still open

- **`TransportCancelled` remains unreachable.** Producing one needs a
  `CancelToken` on `HttpRequest`, and the caller who would cancel — a screen
  being left, a search box typed in again — is a presentation package that may
  not see `http_dio`. The shape would be an outcome the app supplies, as in
  §2.4. It stays absent until something wants to cancel; a contract with no
  caller is the mistake this note's own §1 is about.
- **No certificate pinning.** The `HttpClientAdapter` seam is where it goes and
  `TransportCertificateRejected` already exists to name the failure. It needs a
  certificate, which this repository has no backend to obtain one from.
- **Nothing authenticates the `sync` outbox differently.** A command drained
  hours after it was written is authorised with whatever token is current at
  drain time, which is right; what is untested is a drain that spans a session
  ending.
