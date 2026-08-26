# settings_core

The settings use cases and the adapter that answers them, in one package. The application and infrastructure halves of a hexagon, without the wall between them.

## What a reduced split actually gives up

Nothing about the *shape*. `PreferencesStore` is still declared in `settings_api`, the use cases still depend on it and not on a store, and `KeyValuePreferencesStore` still implements it. A composition root still joins the two.

What it gives up is the **compiler**. In a full split, an import from a use case to an adapter is a `forbidden_dependency` that `arch_check` refuses. Here the two files are in the same package, so the same import compiles and nothing complains. The rule is kept by hand:

- `load_preferences.dart`, `apply_preference_change.dart`, `preference_change.dart` and `settings_coordinator.dart` import `settings_api` and `core_ports`. None of them imports `key_value_preferences_store.dart` or `preferences_dto.dart`.
- `key_value_preferences_store.dart` and `preferences_dto.dart` import no use case.

Keep that and the day this feature needs two adapters, the split is a `git mv` and two pubspecs. Break it and the split is a rewrite — which is the failure mode a reduced split is actually exposed to, and the reason it is a *starting point* rather than a discount.

## The row this package sits on is the widest in the constitution

`feature_core` may depend on own `_api`, `core_kernel`, `core_ports`, `platform/*` **and** a foreign `_api` — the only feature row that carries both of the last two. So `arch_check` would let `KeyValuePreferencesStore` import `identity_api` and take an `ActorId`.

It does not, and the restraint is the point. `PreferencesStore` promises a `String`, because a driven port whose signature names another feature is a port its own adapter cannot implement once it lives in an `_infrastructure` package. The `ActorId` stops at `SettingsCoordinator`, which is the application half and the one place a caller's identity belongs.

## The fallback rule is three cases, not two

`LoadPreferences` is the only rule this feature has that is worth the name:

| What the store said | What the caller gets | Why |
|---|---|---|
| nothing stored | the defaults | they have never chosen anything |
| a record nobody can read | the defaults, and a warning in the log | losing three choices beats a settings screen that will not open |
| no answer at all | `PreferencesUnavailable` | answering the defaults would let the next write put them over choices that were never read |

Collapsing the last two into one failure is the mistake this table exists to prevent, and it is why `settings_api` declares `PreferencesCorrupted` and `PreferencesUnavailable` separately.

## `ResolveLanguage` is not a use case and not in `_api`

Not a `UseCase`, because `UseCase.call` returns a `Future` and this decision touches nothing outside itself; wrapping it would make every call site `await` something that never suspends. Not in `settings_api`, because which languages a build ships changes with every release, and a contract that moves that often is one other features should not be able to depend on.

## What it may depend on

`core_kernel`, `core_ports`, `settings_api`, `identity_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row, minus `platform/*` — this feature reaches the disk through `KeyValueStore`, a port, and has no need of a device API. `core_testing` is a dev dependency: the fakes are used by `test/` and never by `lib/`.

## What must never live here

- **An import from a use case to an adapter, or the other way.** See above. This is the whole discipline of the package.
- **`DateTime.now()` or `Random()`.** Rules A1 and A2. Nothing here needs a clock, which is why neither appears in the constructor lists.
- **A `SettingsFacade` a screen constructs for itself.** A composition root builds the coordinator; presentation packages are handed one.
- **The list of languages the build ships.** It is passed to `ResolveLanguage`, not declared in it.

## Code generation

None. `PreferencesDto` is three string fields and a hand-written codec, which is less code than the `build.yaml` that would produce it.
