# design_system

The component library. Every screen in the product is drawn with what is exported here, and with nothing else.

## What it may depend on

`design_tokens`, the Flutter SDK, and third-party packages.

Section 2 of [`docs/DEPENDENCY_RULES.md`](../../../docs/DEPENDENCY_RULES.md) also allows `core_kernel` on this row. It is deliberately absent.

That is worth stating plainly, because "the row allows it" is the most common reason a dependency gets added in a repository like this one. Nothing here needs a `Result` or a `ValueObject`: a component takes a `String` that has already been resolved and a `PeykIntent` that the calling feature has already decided on. An allowed dependency that nothing needs is still an edge in the graph, still a package that has to be rebuilt, and still one more thing a reader has to rule out.

## Material is an implementation detail

`Scaffold`, `InkWell`, `Material` and `ThemeData` appear inside `lib/src/`. No presentation package imports `package:flutter/material.dart` anywhere in the workspace — they import `design_system` and get `PeykScreen`, `PeykButton`, `PeykListRow`.

The practical consequence: if this product ever stopped being a Material one, the diff would be confined to this package. The fourteen presentation packages would not change at all.

## The two `gen-l10n` sites, and the line between them

§4.1 of [`CLAUDE.md`](../../../CLAUDE.md) puts `flutter gen-l10n` in `apps/*` **and** in `design_system`. They own different sentences, and the test for which is which is who the sentence is about.

| | `design_system` | `apps/*` |
|---|---|---|
| Owns | sentences about a **component** | sentences about the **product** |
| Examples | "Try again", "Loading", "3 unread", "Selected" | "Scan a parcel", "Cash on delivery", every failure line |
| Why here | fourteen callers would each supply their own spelling — and each get the Turkish plural rule wrong | only the app knows which languages ship and what the words are |

A component string is one a caller could not usefully vary. `PeykBadge` needs "3 unread" in the right plural form for the locale; making that a parameter would move a grammar problem into fourteen packages that have no reason to think about grammar.

## How a product string reaches a screen

A presentation package writes a key — `settings.theme.dark` — and never a sentence. It resolves the key through [`StringCatalogue`](lib/src/string_catalogue.dart), which is declared here and satisfied by an app.

This is the driven-port inversion applied to the UI layer, and it exists because of a gap in the dependency table: a presentation package may depend on `design_system` and may not depend on an app, but the app is the only package that knows the product's languages. So the contract is declared on the row both sides can see.

`StringCatalogue.resolve` returns a `String` and cannot fail. A `Result` would put a failure branch behind every label on every screen for something that is not a runtime condition at all: a key with no entry behind it is a mistake in the source, and the place it should fail is the catalogue's own test.

[`KeyEchoCatalogue`](lib/src/key_echo_catalogue.dart) ships here, beside the contract, for the reason §2.2 of the dependency rules gives — a fake belongs with the interface it imitates. `app_harness` uses it as its real catalogue, because a harness proving every feature can be stood up wants to see *which* key each screen asked for.

## Two decisions that look like details

**`PeykTheme.lerp` switches palettes at the halfway point instead of interpolating.** Interpolating two palettes produces colours that exist for 220 milliseconds and were never held to the contrast bar the two ends were — every intermediate frame of a light-to-dark transition is a palette nobody checked. A hard switch is one unchecked frame instead of thirty.

**Colour is never the only signal.** `PeykChip` always draws its label; `PeykOptionRow` marks the chosen option three ways — a wash, a word, and `Semantics(selected:)`. Roughly one courier in twelve cannot tell the success wash from the danger one, and both are chips of the same size in the same place. The component tests assert this rather than trusting it.

## `PeykTheme.wrap` is a test helper that lives in `lib/`

Fourteen presentation packages write widget tests against these components. Each of them needs a tree carrying a palette, a locale, the generated delegates and a catalogue. Leaving that to the callers produced fourteen wrappers that drift; putting it here means a component which grows a new ambient requirement is fixed once.

Its default catalogue is `KeyEchoCatalogue`, which is what lets a widget test assert `find.text('settings.theme.dark')` — a claim about which string the screen asked for — instead of asserting a translation that changes the next time somebody improves the wording.

## What must never live here

- **A feature's word.** `PeykIntent.danger`, never `PeykIntent.overdue`. A component that took a `ShipmentStatus` would be a design system that had learnt what a shipment is.
- **A product sentence.** See the table above.
- **A raw number or colour reaching a caller.** Callers get components; `design_tokens` is not re-exported.
- **A `core_ports` dependency.** Not on this row, and nothing here needs a `Clock`.
- **A font or asset file.** A design system that shipped a font would make every app that draws a button carry it.

## Code generation

`flutter gen-l10n`, configured in [`l10n.yaml`](l10n.yaml). Its output goes to `lib/src/l10n/` and is committed, rather than being left in the synthetic package Flutter defaults to: a generated file that only exists inside `.dart_tool` cannot be reviewed in a pull request, and cannot be seen by the affected-test selection phase 8 derives from `git diff` (§4.3).

No `build_runner`, no `build.yaml`. `gen-l10n` is the one generator in §4.1 that build_runner does not drive, which is why it has its own melos script — `dart run melos run l10n`.
