# observability_bloc

The `BlocObserver` that turns state-machine activity into records on the `Logger` port.

## What it is for

| Type | Implements | Role |
|---|---|---|
| `PeykBlocObserver` | `bloc.BlocObserver` | every bloc's creation, transitions, failures and close, as log records |

The same shape as `ClockTimeProvider` next door in `analytics_otel`: a third-party interface satisfied *using* a core port, rather than a core port implemented using a third-party library. It is the direction that makes a platform package the right home — a presentation package may not see `core_ports`, and an application package may not see `bloc`.

## What it may depend on

`bloc` and `core_ports`. Not `flutter_bloc` and not the Flutter SDK: an observer sees blocs, not widgets.

## What must never live here

- **A state's contents.** Every field recorded is a type name. See below.
- **A destination.** Where a record goes is the `Logger` adapter's business; this package cannot name a collector, a file or a console.
- **`Bloc.observer = …`.** Installing a global belongs to an app's composition root, by §1.2.7.
- **Domain vocabulary.** Nothing here knows what a shipment is; it reads `runtimeType` and stops.

## Three decisions worth knowing about

**Types, never values.** `Transition.toString()` prints both states in full, and in this product a state holds a session with somebody's name, a consignee's address and a captured signature. A log aggregator is the easiest place for other people's data to leave a courier platform, so the observer records which bloc, which event and which two state types — and nothing that came out of a state object. `_nameOf` is a single function for exactly that reason: adding a value is a decision somebody has to make in one visible place.

**`onTransition` and not `onChange`.** Every bloc emission produces both, and the transition is the one that also names the event that caused it. Overriding both would double every line. A `Cubit` emits a change with no transition and would go unrecorded — a gap this workspace does not have, because nothing in it is a cubit.

**`onError` is the reason to install an observer at all.** A handler that throws is caught by bloc: the state does not change, nothing reaches the zone's error handler, and a screen stops responding with no evidence anywhere in the process. `super.onError` is still called, so bloc's own rethrow in tests keeps working.
