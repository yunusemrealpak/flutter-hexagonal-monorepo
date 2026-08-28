# vehicle_inventory_presentation

The vehicle inventory UI: the screen a courier counts a van on.

## No scanner

A presentation package may not depend on `platform/*`, so a barcode arrives as a `ShipmentId` from whatever the app wired to the trigger. That is the same decision `delivery_presentation` made about the camera in phase 5, and it is why this screen is testable without a device.

## No arithmetic

The scanned count, what is missing and what should not be in the van all come off `LoadCount`. A screen that computed them would be a second implementation of the only arithmetic this feature has, and the two would disagree the day one of them was fixed.

## The screen resumes before it starts

A phone killed mid-count leaves an open count behind. A courier made to start again would rescan a van they had already half counted, which is how a count ends up disagreeing with itself.

A scan that arrives while the screen is preparing is **ignored**. A scanner fires whenever a trigger is pulled, and a scan with no count to go into would otherwise be counted against the wrong manifest.

## What it may depend on

`core_kernel`, `core_navigation`, `identity_api`, `shipments_api`, `vehicle_inventory_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row.

## What must never live here

- **`vehicle_inventory_core`, or any `platform/*`.** Contracts only, and no device.
- **`core_ports`.** Not on this row.
- **A sentence.** Labels are localisation keys; `CountScreen.describe` is the deliberate exception.

## Code generation

None.

## Missing is danger, unexpected is warning

They are not the same thing and they are not drawn the same way. A parcel the manifest lists and the van does not have is a delivery that will not happen; a parcel nobody expected is paperwork. `CountScreen` draws the first as `PeykIntent.danger` and the second as `PeykIntent.warning`, and that mapping is this feature's — a component library that knew which one was worse would be a component library that had learned what a van is.

The numbers still come off `LoadCount`. Phase 6 wrote the rule down: a count is derived, never stored, so a widget that added anything up would be a second place the total could be wrong.

## A finished or missing count offers no retry

`CountScreen.canRetry` is false for `CountClosed` and `CountMissing`. Neither is reopened by asking again — both need a *new* count, which is a different action on a different screen. The retry that is offered calls `resume()`, because what failed was the question "is a count already open", and asking again is exactly that question.
