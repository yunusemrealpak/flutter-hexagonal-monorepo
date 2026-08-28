# shipments_presentation_courier

The shipments UI as a courier sees it: a stop list, and the scan flow it leads to.

## One half of scenario 7

`shipments_presentation_dispatcher` is the other. The two consume the same `shipments_api` — the same `ShipmentsFacade`, the same `ShipmentSummary`, the same state machine — and show completely different screens. That is what makes a driving adapter *replaceable* rather than merely swappable in principle.

The difference shows up in the route table too: these routes are guarded by `viewAssignedShipments`, the dispatcher's by `viewAllShipments`.

## Contracts only

This package holds no adapter and no use case, and it cannot: §2 forbids a presentation package from depending on any `_application`, `_infrastructure` or `platform/*`. What it declares is what it needs — `ShipmentsFacade` to ask, `SessionReader` to know whose manifest to ask for — and an app decides what answers. The real coordinator in `app_courier`, a fake in `app_harness`.

`SessionReader` rather than `IdentityFacade`, deliberately. A screen whose job is drawing a list should not also be able to sign the user out.

## Three decisions in the state type

`CourierManifestState` is a sealed union of four cases, not one class with `isLoading`, `rows` and `failure`. The flat shape lets a widget be handed a loading state that also has rows and a failure, and the day two of those are set at once nobody can say what should be on screen. Here the compiler answers it.

**An empty manifest is `ManifestReady([])`, not a failure.** "Nothing assigned to you yet" is an ordinary morning, and an error for it would have couriers calling the depot before their first parcel.

**`ManifestFailed` carries a `ShipmentFailure`, not a `String`.** Turning a failure into a sentence happens at the widget, where the locale is known. A formatted English string in a state object is untranslatable a phase later.

## Why a `ChangeNotifier` and not a bloc

A deliberate non-decision. No state management library is a dependency of this workspace yet, and introducing one in phase 4 would make every feature inherit the choice before there is a reason for it.

The state type is the part that matters. Swapping in a bloc, a cubit or a signal changes `CourierManifestController` and nothing else, because the widget renders `CourierManifestState` and does not know what produced it.

## Why the screens are plain

Colours, typography and spacing come from `design_system`. What has not changed is the part that never was going to: a screen renders a sealed state exhaustively and reaches nothing but ports.

`CourierManifestScreen.intentOf` is where a shipment status becomes a colour, and it is **not** the mapping the dispatcher's board makes. `undeliverable` is a warning here — the visit is over and the parcel goes back to the depot, which is a normal outcome of a delivery round — and a danger there, because on that screen it is a parcel somebody has to do something about today.

That disagreement is the half of scenario 7 that only two presentation packages can demonstrate. A status is one fact; what it *means to the person looking at it* is two, and neither package could say so if the mapping lived in `shipments_api`.

## What it may depend on

Own `_api`, other features' `_api`, `core_kernel`, `core_navigation`, `design_system`, and the Flutter SDK.

## What must never live here

- **A business rule.** The state machine is in `shipments_api`. A screen that decided what may follow what would disagree with the dispatcher's screen within a release.
- **Any `_application` or `_infrastructure` package.** A widget that constructed its own use case would have to know which adapters are behind it, and that decision belongs to an app.
- **A formatted message in a state object.** See above.
- **`debugPrint`.** Rule A4 — use the `Logger` port.
