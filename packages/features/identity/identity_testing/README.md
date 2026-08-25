# identity_testing

Fakes, fixtures and a contract kit for identity. Consumed by other packages' tests, never by production code.

## What it is for

| Type | Role |
|---|---|
| `SessionBuilder` | a valid, unremarkable session by default; a test names only what it is about |
| `InMemorySessionStore` | a store that really stores, where a miss is `Success(null)` |
| `FakeCredentialGateway` | really issues a session bound to the device it was handed, and counts refreshes |
| `FakeDeviceRegistry` | can change its mind between calls |
| `runSessionStoreContract` | one suite, run against every `SessionStore` |

## Two fakes that exist to make a rule reachable

**`FakeCredentialGateway` honours the binding it is given.** The use case decides which device a session is issued for, and passes it in. A fake that ignored that argument would let the use case stop passing it and no test would notice — and the app would ship sessions bound to whatever the server felt like.

**`FakeDeviceRegistry.binding` is mutable.** The specification's second rule — a session whose device tie has broken is refused — can only be reached by a registry that reports one fingerprint at sign-in and a different one afterwards. Without that, the branch is unreachable and the rule is untested.

## The contract kit

`runSessionStoreContract` runs here against `InMemorySessionStore` and in `identity_infrastructure` against `SecureSessionStore`. A session store is the piece most likely to be reimplemented per platform, and the piece where a behavioural difference is least visible: an app that quietly forgot a session on restart looks like a login bug, not a storage bug.

The kit asserts the fields the two business rules actually read — the refresh window and the device fingerprint — because a store that dropped either would produce an app that signs people out at apparently random moments.

## What it may depend on

Own `_api`, `core_kernel`, `core_ports`, `core_testing`, and other features' `_api` packages.

`test` is a runtime dependency here rather than a dev dependency, because a contract kit *is* tests: it calls `group` and `test` from `lib/`. `core_testing` does the opposite, because it ships only fakes.

## What must never live here

- **Any implementation package.** A fake bound to `identity_application` would break whenever those use cases were refactored.
- **A mock.** These are fakes; they really store and really issue.
- **A fake that cannot fail.** Failure is part of a port's contract, and the branches that handle it are the ones that run on a bad day.
- **`DateTime.now()`.** `SessionBuilder.now` is a constant, which is why a token's remaining life is expressed as a `Duration` from it.
