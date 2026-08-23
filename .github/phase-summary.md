## Phase 2 — Platform packages

The driven adapters. Every port declared in phase 1 that has a real implementation gets one here, and every technology the product touches is confined to exactly one package.

### Packages added: 9

| Package | Implements | Also declares | Technology |
|---|---|---|---|
| `http_dio` | — | `HttpTransport`, `TransportFailure`, `FakeHttpTransport` | `dio` |
| `storage_drift` | `KeyValueStore` | `PeykDatabase`, two DAOs, `storeFailureFrom` | `drift`, `sqlite3` |
| `analytics_otel` | `AnalyticsSink`, `Logger` | `ClockTimeProvider`, `otelAttributes` | `opentelemetry` |
| `secure_store` | `SecureStore` | `secureStoreFailureFrom` | `flutter_secure_storage` |
| `device_permissions` | `PermissionRequester` | the ask log that earns `notDetermined` | `permission_handler` |
| `connectivity_monitor` | `NetworkStatus` | `toNetworkCondition` | `connectivity_plus` |
| `location_service` | — | `LocationSource`, `GeoFix`, `LocationFailure`, fake | `geolocator` |
| `media_capture` | — | `MediaCapture`, `CapturedMedia`, `CaptureFailure`, fake | `image_picker` |
| `push_messaging` | — | `PushMessagingClient`, `PushMessageDto`, fake | `firebase_messaging` |

Every one of them depends on `core_kernel` and/or `core_ports` and nothing else from the workspace. No platform package depends on another.

### Which architectural rules become visible here

**Where a contract is declared.** The phase's main finding, now written into `CLAUDE.md` §1.1.1 and `DEPENDENCY_RULES.md` §2.2. `core_ports` speaks the product's words — a clock, a store, a permission — and a port enters it only when more than one feature needs the capability and none owns it. `platform/*` speaks a technology's words, and a contract lives beside its adapter. Nothing in the product asks for "an HTTP request" or "a GPS fix", so `HttpTransport`, `LocationSource`, `MediaCapture` and `PushMessagingClient` are declared where their adapters are. The dependency table already enforced the consequence without anyone having noticed: `_application` may not depend on `platform/*`, so a use case can never see an `HttpRequest` and can never end up owning a retry policy.

**A fake belongs with the contract it imitates.** `FakeHttpTransport` ships from `http_dio`; `InMemorySecureStore` stays in `core_testing` because `SecureStore` is declared in `core_ports`. Same rule, two answers, and the rule is what makes them consistent.

**`platform/*` → `platform/*` bites in practice, not in theory.** Three packages need a permission and a fourth grants it. The resolution is the constitution's own: depend on the port, take it through the constructor, let a composition root supply the adapter. `location_service`, `media_capture` and `push_messaging` all take `PermissionRequester`; none of them has ever heard of `device_permissions`.

**The adapter is the boundary.** Every one of these packages ends every throwing path in a `Failed`. `DioHttpTransport`, `KeychainSecureStore` and the rest carry an `on Object` catch, and each has a test that throws something the plugin never promised specifically to prove the catch is a boundary and not decoration.

**A sealed failure earns its cases by what a caller does about them.** `SecureStoreKeyInvalidated` is separate from `SecureStoreUnavailable` because the first means the credential is gone and only a fresh sign-in helps — collapsing them produces an app that offers "try again" for a secret that no longer exists. `LocationPermissionBlocked` is separate from `LocationPermissionDenied` because iOS shows no second prompt, so an app that could not tell them apart would offer a button that does nothing. `CaptureCancelled` is a failure case that is not an error at all.

**Code generation lands where §10.1 says.** `drift_dev` in `storage_drift`, `json_serializable` in `push_messaging` for a DTO, and nowhere else. Both packages carry a `build.yaml` that enables one builder and narrows `generate_for` to `lib/src`. Packages with no generated files have neither `build_runner` nor `build.yaml`.

### Deviation from the specification: a ninth platform package

The specification lists eight. `PermissionRequester` has no natural owner among them — `media_capture` needs the camera grant, `location_service` needs location, `push_messaging` needs notifications, and one plugin covers all three. Hosting the adapter in any of them would force the other two to depend on it, which the constitution forbids. `device_permissions` is that ninth package; workspace totals are now 75 packages rather than 74.

### Two things that had to change outside the packages

**The workspace now resolves with `flutter pub get`.** Six of the nine packages wrap Flutter plugins, and a pub workspace resolves as one unit, so the root command changed for everyone. `melos run test` split into `test:dart` and `test:flutter` — a package that depends on the Flutter SDK cannot be run by `dart test`, and `flutter test` has no `--preset`, so the pr preset's exclusions are spelled out in the script while the tag definitions stay in each package's `dart_test.yaml`.

**The pinned toolchain moved to Flutter 3.47.1 / Dart 3.13.1.** Flutter 3.44.2 pins `meta 1.18.0`, `test_api 0.7.11` and `matcher 0.12.19`, and in a workspace those pins are global. They propagated into a chain nothing could satisfy: flutter_test's pin held `test` at 1.31.0 → analyzer below 13 → drift_dev at 2.34.0 → `cli_util ^0.4`, against melos 8.3.0's `cli_util ^0.5`. Every tool in the repository would have had to move backwards to accommodate one SDK pin. The rejected alternative was `dependency_overrides` on the three packages — which would have left flutter_test running against a `test_api` it did not pin, in a repository whose purpose is to demonstrate rules being followed rather than worked around.

### Three bugs the tests caught

1. **Drift returned local `DateTime`s.** With integer storage a value written as `12:00Z` reads back as `15:00` in Istanbul — the same instant, a different object, and `DateTime.==` compares the UTC flag. `Clock` promises UTC. Fixed by `store_date_time_values_as_text: true`, which is now documented in `storage_drift`'s `build.yaml` with the reason.
2. **`ConnectivityMonitor.changes()` dropped events.** Written as an `async*` generator, it did not subscribe to the broadcast source until its first yielded value had been consumed — reintroducing exactly the gap the port's "emits the current value on subscription" promise exists to close. Rewritten with `Stream.multi`.
3. **`OutboxDao.recordAttempt` did not increment.** A `Value.absent()` in a companion leaves a column unchanged; the counter is now incremented in SQL, so two drains of the same outbox cannot both write the same value.

### Verification

`arch_check` does not exist until phase 3, so the rules were verified by hand and every commit body records which ones.

```
$ dart run melos run analyze        # dart analyze --fatal-infos --fatal-warnings .
No issues found!

$ dart run melos run gen:check      # gen + git diff --exit-code
SUCCESS

$ dart run melos run test           # pr preset, both runners
core_kernel 28 · core_ports 5 · core_navigation 9 · core_testing 38
http_dio 13 · storage_drift 23 · analytics_otel 16
device_permissions 13 · secure_store 12 · connectivity_monitor 13
location_service 19 · media_capture 13 · push_messaging 24
                                                    226 tests, all passing
```

Hand-verified per commit: the §1.1 dependency table for each package, S1/S2/S3/S5/S6, A1–A4 (`grep -rnE "DateTime\.now\(\)|Random\(|print\(" packages/platform/` is empty), G4 for the two packages with generated files, and invariant 1.2.9 at every adapter boundary.

### Known gaps

- **`arch_check` still does not exist**, so §2.2's new rule about where a contract is declared is a review responsibility until phase 3 encodes it. It is not obviously mechanical: telling "a technology's words" from "the product's words" may stay a judgement call.
- **No adapter has run on a device.** These are compiling, tested adapters with substituted platform implementations. Phase 7's `app_harness` is where they first meet a real one, and the specification does not require iOS or Android builds before then.
- **`FeatureFlagReader` and `DomainEventBus` have no adapter yet.** Neither maps onto a platform capability: the first wants a remote configuration service and the second is in-process. Both are phase 5 and phase 7 work.
