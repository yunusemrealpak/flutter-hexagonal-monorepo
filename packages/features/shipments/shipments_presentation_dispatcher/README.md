# shipments_presentation_dispatcher

The shipments UI as an operations desk sees it: a board of every shipment, a selection, and permission-gated bulk actions.

## Scenario 6 lives here

`DispatcherBoardController` takes identity's `PermissionChecker` and asks *may this actor bulk-assign?* The answer is a `bool`.

This package does not know that identity has roles, that a role carries a `PermissionSet`, that an actor can hold a personal grant, or that any of it is decided by a class called `Actor`. If identity replaced all of that tomorrow, nothing here would change. The test proves it: the whole coupling to identity is a three-line fake `PermissionChecker`.

The port is also the *smallest thing that answers the question*. Identity publishes `IdentityFacade` too, and handing the board that instead would give a screen whose job is drawing a table the ability to sign the user out.

**The check is in the controller, not only on the button.** A button that appears and then refuses teaches a dispatcher to distrust the screen — so `canBulkAssign` gates the rendering. But `assignSelected` checks again, because a controller is reachable from a keyboard shortcut, a deep link and a test, and a rule that lives on a widget is a rule those three do not have.

None of it is a control. The server checks again; a permission check in a client is a courtesy.

## The other half of scenario 7

`shipments_presentation_courier` consumes the same `shipments_api` and shows a stop list. Same facade, same summaries, same state machine, different screen — and different routes, guarded by `viewAllShipments` here and `viewAssignedShipments` there.

## Why `DispatcherBoardState` is not shared with the courier's

The two look alike today and diverge the moment the board grows a filter or a sort — at which point the shared type would have three fields the courier's screen never sets.

Two features that happen to have the same state shape are not the same feature, and a `shared` package for it is precisely the mistake the constitution forbids (§2, rule 4).

## What it may depend on

Own `_api`, other features' `_api`, `core_kernel`, `core_navigation`, `design_system` (from phase 7), and the Flutter SDK.

## What must never live here

- **Any `_application` or `_infrastructure` package.** What answers `ShipmentsFacade` is an app's decision.
- **Identity's implementation.** The whole point of scenario 6 is that this package sees `PermissionChecker` and nothing behind it.
- **A business rule.** The state machine is in `shipments_api`.
- **`debugPrint`.** Rule A4.
