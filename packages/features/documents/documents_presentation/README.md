# documents_presentation

The documents UI: the screen that shows a piece of paperwork and hands it to whatever the app shares with.

## Sharing arrives as a callback

A presentation package may not depend on `platform/*`, and sharing has no `platform/*` package behind it. So the app supplies a function and this package calls it — the same decision `delivery_presentation` made about the camera in phase 5, and the reason `DocumentsFacade` has no `share` on it.

An app that supplies none gets a screen with **no share control**, rather than one that does nothing when pressed. `DocumentController.canShare` is what the widget asks.

Sharing does nothing unless a document is on screen. Sharing what a person cannot see is how somebody sends the wrong waybill to a customer.

## The screen does not render the document

A PDF viewer is a platform capability too. What is shown is the document's identity and size; an app that has a viewer puts it where the placeholder is.

## Loading is one state

"Reading the archive" and "asking the server" are a distinction a person cannot act on, and a screen that showed it would be explaining caching to somebody standing at a door.

## What it may depend on

`core_kernel`, `core_navigation`, `documents_api`, `shipments_api`, `flutter`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row.

## What must never live here

- **`documents_core`, or any `platform/*`.** Contracts only, and no device.
- **A share implementation.** See above.
- **A sentence.** Labels are localisation keys; `DocumentScreen.describe` is the deliberate exception.

## Code generation

None. The route is parameterised but there is one of it.
