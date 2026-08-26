# delivery_presentation

The delivery UI: the screen a courier taps *done* on.

## What it may depend on

`core_kernel`, `core_navigation`, `delivery_api`, `identity_api`, `shipments_api`, the Flutter SDK

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. A dependency outside it is a violation rather than an exception; `dart run melos run arch:check` will say which rule and how to fix it.

`identity_api` is scenario 6 and `shipments_api` is one identifier — which parcel this visit is about. Nothing here names a `Shipment`.

## Scenario 6, checked twice at two distances

`ProofCaptureController.canComplete` asks `PermissionChecker` whether the signed-in actor may record a hand-over, and learns nothing else: not the role, not the grant, not that `Actor` exists. `shipments_presentation_dispatcher` asks the same port before rendering bulk assignment — two features, one contract, no shared implementation.

The check happens twice on purpose. `DeliveryRoutes` carries `requiredPermission: 'completeDelivery'`, so an app's router keeps the wrong person off the screen; the controller asks again before the action, because a grant can be revoked while a courier is standing at a door and they are already past the router by then.

The use case does *not* check permissions — identity is not one of its collaborators — so the button guard is the last thing between an actor without the grant and a recorded delivery. Recording that a delivery did *not* happen needs no grant: every courier at a door may say what they found, and gating it would leave the visit unrecorded rather than leaving it undone.

## Two constraints this package makes visible

**The camera arrives as a callback.** Capturing a signature or a photograph means `platform/media_capture`, and section 2 forbids a presentation package from depending on `platform/*`. So the app supplies the capture, the screen offers the button, and the evidence comes back as a value from `delivery_api`. An app with no camera passes nothing and the button is not drawn.

**There is no clock, and there cannot be.** This row does not include `core_ports`. `ProofOfDelivery.from` derives the hand-over's instant from the evidence, which is why the constraint costs nothing — and is the more honest answer anyway.

## What must never live here

- **`delivery_application`, `delivery_infrastructure` or any `_core`.** Presentation knows the vocabulary, not the use cases and not the adapters.
- **A second copy of the proof rule.** `AtTheDoor.missing` asks `ProofPolicy` in `delivery_api`. A copy here would tell a courier they were finished on the day the policy changed and the use case disagreed.
- **A colour, a spacing value or a date format of its own.** Those come from `design_system` in phase 7.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency — the cheapest configuration, not a missing one.
