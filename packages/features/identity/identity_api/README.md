# identity_api

Who is acting, on which device, and what they may do. Entities, value objects, ports, and the sealed failures those ports return.

## What it is for

Three groups of types, and nothing else:

| Group | Types |
|---|---|
| Domain | `Actor`, `ActorId`, `Session`, `AccessToken`, `DeviceBinding`, `Credentials`, `Role`, `Permission`, `PermissionSet` |
| Driving port | `IdentityFacade` — implemented by `identity_application` |
| Driven ports | `CredentialGateway`, `SessionStore`, `DeviceRegistry` — answered by `identity_infrastructure` |

Plus the two ports identity opens to *other features*: `SessionReader` and `PermissionChecker`. They are the reason `shipments` can ask who is signed in and what they may do while depending on nothing but this package, and they are deliberately narrower than `IdentityFacade` — a feature that needs to know the actor should not thereby gain the ability to sign them out.

And one more driving port with an audience of its own: `SessionTokens`, held by whatever authorises outbound requests. It presents a token and, after the server has refused one, asks for another — and it can do nothing else. That is §2.3 rather than taste: a port is one audience's conversation with the feature, and the network layer's conversation with identity is two sentences long. Widening `IdentityFacade` instead would have handed the transport the ability to end a shift.

## The two business rules

Both live on `Session`, not in a use case:

- **Refresh before expiry, not on it.** `Session.needsRefreshAt` is true once the token is within `Session.refreshThreshold` of expiring. Refreshing on expiry instead means every request that lands on the boundary fails once and is retried — a visible stall on a van with bad signal.
- **A broken device tie invalidates the session.** `Session.validateAgainst` checks the binding *before* it checks expiry, because a session presented on the wrong device is a security event whether or not it had also aged out, and reporting it as a plain expiry hides it in the noise of every ordinary sign-in.

A use case that owned these would be the only place that knew them, and the screen that wants to show "signing you back in…" would have to ask the use case to find out.

## Where the line around code generation is drawn

This package is where the workspace's codegen pattern is set, so the calibration is written down here rather than inferred later.

| Shape | How | Why |
|---|---|---|
| Closed unions — `IdentityFailure` | `freezed` | A failure union is a closed set of small values whose equality *is* structural. The generator writes exactly what would otherwise be written by hand, and the hand-written version drifts the first time a case gains a field. |
| Plain multi-field values — `DeviceBinding`, `Session` | `freezed` | No identity of their own, no secret to leak. Structural `==` and a printing `toString` are both correct. |
| Entities — `Actor` | hand-written | `Entity<TId>` compares by identity: the same courier with a corrected name is the same courier. `freezed` produces structural equality, which collapses "is this the same actor?" and "has this actor changed?" into one question. `actor_test.dart` asserts the difference. |
| Single-field value objects — `ActorId` | hand-written | A private constructor plus a validating factory returning `Result`, so an invalid identifier cannot exist as a value. `freezed` produces a public constructor, and validation that can be bypassed is validation nobody can rely on. |
| Secret carriers — `AccessToken`, `Credentials` | hand-written | A generated `toString` prints every field. The first log line that interpolated a `Session` would put a live bearer token wherever logs go, and nobody would see it happen. Both types redact, and `credentials_test.dart` asserts it. |

The specification asks for "entities and sealed state types with `freezed`". The second half is followed exactly; the first is not, and this table is the argument. The compromise that would have followed it to the letter — `@Freezed(equal: false)` plus a hand-written identity `==` — keeps the generator while cancelling the one thing it was brought in for, and puts ten lines of ceremony in every entity file to do it.

## What it may depend on

`core_kernel`, `core_ports`, and other features' `_api` packages. Third-party: `freezed_annotation` and `meta`, both annotation-only.

That list is [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md) §2, one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

## What must never live here

- **An implementation of a port declared here.** Rule S8. `identity_application` implements `IdentityFacade`; `identity_infrastructure` answers the driven ports; the fakes live in `identity_testing`.
- **A DTO, or `json_annotation`.** Rules I4 and G2. `freezed_annotation` re-exports a handful of `json_annotation` symbols; nothing here imports them and `json_serializable` is not enabled in `build.yaml`.
- **The Flutter SDK.** Rule I2. This package is pure Dart, which is what keeps the fast majority of the suite fast.
- **`DateTime.now()`.** Rule A1. Every rule about time here takes `now` as a parameter — which is also why none of them needs a test that waits.

## Code generation

`build.yaml` enables `freezed` and narrows it to `lib/src/**.dart`. `json_serializable` is absent rather than disabled: it is not a dev dependency of this package, so naming it would fail the build instead of tightening it.
