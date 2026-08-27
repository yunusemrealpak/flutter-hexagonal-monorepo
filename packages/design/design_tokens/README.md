# design_tokens

The product's design decisions, expressed as values: a palette, a spacing scale, a type scale, corner radii, motion durations and layout breakpoints.

## What it may depend on

The Flutter SDK. Nothing else.

That is the entire row in section 2 of [`docs/DEPENDENCY_RULES.md`](../../../docs/DEPENDENCY_RULES.md) — no `core_kernel`, no third-party package, and `allow_third_party: false` in `rules.yaml` says so explicitly. Only two package types in the workspace are forbidden third-party dependencies, and this is one of them.

The SDK is here for three types and no more: `Color`, `FontWeight` and `Brightness`, all from `dart:ui`.

## Why a token is not a `TextStyle` and not a `ThemeExtension`

Both would compile. Both would be wrong, and for the same reason.

A `TextStyle` carries a colour. Which colour depends on the palette in force and on what the text is sitting on — a decision that needs to know about surfaces, states and the widget tree. So the type scale here stops at four numbers ([`PeykTypeToken`](lib/src/peyk_type_token.dart)) and `design_system` combines them with a palette slot.

A `ThemeExtension` is a Flutter *mechanism* for carrying values down a widget tree. This package has no widget tree. `PeykPalette` is a plain object with two `const` instances, and `design_system` is what puts one of them into a `Theme`.

The line is: **a token is a value somebody chose; a theme is how it reaches a widget.** Keeping them apart is what stops this package from growing into a second component library.

## Intents are named for what they mean, not what they are about

The vocabulary is `neutral`, `info`, `success`, `warning`, `danger` — never `delivered`, `overdue` or `settled`. A presentation package maps its own sealed state onto an intent, and that mapping stays with the feature that owns the state.

Naming a colour `delivered` here would put a courier product's domain inside a package whose entire value is having no idea what the product does. It would also be a lie the first time a second thing in the product was green.

## The tests are the reason this package is not just a constants file

[`peyk_palette_test.dart`](test/peyk_palette_test.dart) checks every foreground/background pair in both palettes against the WCAG 2.1 AA contrast ratio, and body text against AAA. A palette is a set of numbers somebody picked by eye; whether a person can read the result is the one property of those numbers that cannot be argued about.

The contrast function is written out in [`test/contrast.dart`](test/contrast.dart) rather than pulled from pub, because a dev dependency here would leave the package's pubspec claiming a relationship the constitution does not give it.

## What must never live here

- **A widget.** Not even a small one. That is `design_system`.
- **A `ThemeData` or a `ThemeExtension`.** See above.
- **A domain word.** `PeykIntent.success`, not `PeykIntent.delivered`.
- **A third-party package.** Including in `dev_dependencies`.
- **A colour that has not been through the contrast test.** Adding a slot means adding its assertion.

## Code generation

None. There is nothing here a generator could produce that a person should not have chosen deliberately, so the package has no `build_runner` dependency and no `build.yaml` — which is the cheapest configuration rather than a missing one (§4.2 of `CLAUDE.md`).
