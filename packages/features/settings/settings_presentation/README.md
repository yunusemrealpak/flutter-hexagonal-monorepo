# settings_presentation

The settings UI: the screen where somebody chooses a language, a palette and what this device may spend their data on.

## What is not here

**No use case and no adapter.** `SettingsController` holds `SettingsFacade` and nothing else. Which implementation answers it is an app's decision, and this package could not name `settings_core` if it wanted to — section 2 does not give this row that edge. That is the same rule that keeps `payments_presentation` away from `payments_application`, and it is worth noticing that the reduced split changes nothing about it: a `_core` package is just as invisible from here as an `_application` package is.

**No clock.** A presentation package gets `core_kernel`, `core_navigation`, contracts and Flutter — not `core_ports`. Nothing on this screen needs one.

**No sentences.** Every label is a key: `theme.dark`, not "Dark". The strings belong to the app's localisation, which arrives in phase 7, and writing English here would mean deleting it then. `SettingsScreen.describe` is the one exception, and it exists so that the exhaustive `switch` over `SettingsFailure` lives somewhere the compiler checks it.

## `SettingsSaving` carries what it is saving over

The state is sealed with five cases, and the interesting one is `SettingsSaving(preferences)` rather than a `isSaving` flag on `SettingsReady`. Carrying the previous value is what lets the screen keep drawing the choices somebody can see while the write is in flight, and it makes a half-applied change unrepresentable: the new preferences only exist as a state once the store has taken them.

The rows are disabled rather than hidden while that is true. A settings screen that emptied itself for the duration of a write would flicker on every tap, and somebody would tap twice because the first tap left no trace.

## A change asked for from a state with nothing to show is refused

`SettingsController` only sends a change when it is already displaying preferences. There is nothing else it could sensibly do: a change applied to a set of preferences that were never read would write defaults over whatever is actually stored, and the person would lose two choices by changing a third.

## The facade's stream is a contract, not a convenience

`SettingsFacade.changes()` exists so this screen can follow a preference changed on another screen or another device. That is why it is on the port rather than being a detail of the coordinator — a controller that could only see its own writes would show a palette nobody has any more.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `settings_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `design_system` is missing because it does not exist yet; it arrives in phase 7 and this package's plain widgets are what it will replace.

## What must never live here

- **`settings_core`.** Rule I5's neighbour in section 2: a presentation package sees contracts, never implementations.
- **`core_ports`.** Not on this row. The temptation is a `Clock` for a "last saved" line; the answer is that a use case stamps instants, not a screen.
- **A `SettingsFacade` this package constructs.** A composition root builds it and hands it over.
- **A sentence in a widget.** See above.

## Code generation

None. `go_router_builder` belongs on this row and there is nothing yet to generate: `SettingsRoutes` declares one destination with no parameters, and a builder producing a type-safe accessor for `/settings` would be a generated file to review in every diff for no gain. It arrives with the app that needs it.
