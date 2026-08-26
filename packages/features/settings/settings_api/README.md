# settings_api

The settings contract: the language, palette and synchronisation policy a person may choose, and the two ports that read and record them.

## Why this feature is three packages and not five

`settings` has one rule worth the name — an unreadable record falls back to the defaults, an unreachable store does not — one outbound adapter, and no offline behaviour of its own. The specification's calibration for that is the reduced split: `_api`, `_core`, `_presentation`. `_api` is separate here as it is everywhere, because it is the only thing that breaks cycles and narrows the blast radius of a change.

The day a second adapter arrives — a remote profile service beside device storage — the use cases and the adapters in `settings_core` are already on opposite sides of the ports declared here, and splitting the package is a move rather than a rewrite. That is the whole reason the reduced split is a starting point and not a discount.

## The two ports disagree about identifiers, on purpose

`SettingsFacade.preferencesOf(ActorId)` beside `PreferencesStore.read(String actorId)`.

A driving port takes the identity, because every caller of it already holds a session. A driven port takes the raw identifier, because a port whose signature names another feature's type is a port its own adapter cannot implement without depending on that feature. In this package the second half is a discipline rather than a compiler error — a `_core` package *may* see a foreign `_api`, unlike an `_infrastructure` — which is exactly why it is written down.

## `UserPreferences` is not an `Entity`

Two couriers who both want Turkish, a dark palette and unmetered-only synchronisation hold the same preferences. There is no sense in which one of them is a different preferences, so the type has value equality and no identifier. The actor is the key the record is stored under, not a field of the record.

## A well-formed language tag is not a supported one

`LanguageTag.parse` accepts `tr` and `en-GB` and normalises their case. It does not check that a translation exists, because which languages ship changes with every release and a construction invariant that moves would make somebody's stored preference unreadable the day a language was withdrawn. Resolving a stored tag against what is actually available is `settings_core`'s job.

## What it may depend on

`core_kernel`, `identity_api`, `meta`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `identity_api` is there for `ActorId` and for nothing else.

## What must never live here

- **An implementation of `PreferencesStore` or `SettingsFacade`.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2. The stored shape belongs in `settings_core`.
- **`flutter`.** Rule I2 — and `ThemePreference` is why it is worth saying: the temptation is to make it a `ThemeMode`, which would put the Flutter SDK in a pure Dart contract for the sake of three enum values.
- **The list of languages the product ships.** See above.

## Code generation

None. No generated file, no `build.yaml`, no `build_runner` dev dependency — CLAUDE.md §7.6 calls that the cheapest configuration rather than a missing one.
