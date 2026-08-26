# payments_presentation

The payments UI: the screen a courier takes money on.

## What it may depend on

`core_kernel`, `core_navigation`, `payments_api`, `identity_api`, `shipments_api`, the Flutter SDK

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. `identity_api` is scenario 6; `shipments_api` is one identifier — which parcel the money is owed against. Nothing here names a `Shipment`.

## Scenario 6, in its third feature

`CollectionController.canCollect` asks `PermissionChecker` whether the signed-in actor holds `Permission.collectPayment`, and learns nothing else. The stand-in in this package's test is four lines — the *same* four lines as in `delivery_presentation` and `shipments_presentation_dispatcher`. Three features, one contract, no shared implementation, and each of them able to fake identity in four lines: that is what the scenario buys.

`PaymentsRoutes` guards its two destinations with two different permissions. Taking money and giving it back are not the same authority — an operation that let every courier refund would have no way to tell a mistake from a theft — and `Permission` has had `collectPayment` and `refundPayment` as separate members since phase 4 for exactly this.

## The amount is read, never typed

It comes from `PaymentStatus`, so a courier cannot collect a different number from the one the operation is owed. A text field here would be exactly where that difference got in, and afterwards it would be indistinguishable from a typing mistake.

`CollectionScreen.render` is the one place in the feature where minor units become a decimal, and it uses the currency's own scale rather than an assumed hundred. Everywhere else an amount is an integer and a currency, which is what keeps a day's total exact.

## What must never live here

- **`payments_application` or `payments_infrastructure`.**
- **An input field for money.** See above.
- **A clock.** This row does not include `core_ports`, and nothing here needs one: the instants a collection carries are stamped by the use case, which has one.
- **A colour, a spacing value or a currency format of its own.** Those come from `design_system` and the app's localisation in phase 7.

## Code generation

None. There is no `build.yaml` and no `build_runner` dependency — the cheapest configuration, not a missing one.
