# vehicle_inventory_api

The vehicle inventory contract: what should be in the van, what was actually scanned, and the difference somebody has to explain.

## The discrepancy is derived, never stored

`LoadCount.missing` and `LoadCount.unexpected` are set arithmetic over the manifest and the scans. Storing them beside the two sets would make a state where the three disagree representable — and that is exactly the state a bug produces, silently, in the record somebody uses to argue about a lost parcel.

`unexpected` matters as much as `missing` and is easier to forget: a parcel in the van that nobody expected is somebody else's parcel, and it is a delivery that will not happen unless the count says so.

## A count closes while it disagrees

That is what it is for. A courier who cannot find two parcels closes with two missing and the operation now knows. A rule that refused to close an incomplete count would leave couriers at the depot with a screen they cannot dismiss, and the discrepancy would travel by message instead of by record.

## Scanning is idempotent

Scanners double-fire, and a courier who cannot tell whether the first beep registered will scan again. Counting the second read would produce a count that never reconciles and a courier who stops trusting the screen. A parcel that is not on the manifest is *recorded* rather than refused, for the reason above.

## `ManifestSource` is not `ShipmentsFacade`

Shipments can already answer "what is on this courier's manifest" — and it answers with `ShipmentSummary`: an address, a consignee, a status. Consuming that would drag all of it into a feature whose whole job is counting. This port answers with **raw identifiers**, so its adapters need not see `shipments_api` at all, and an app's composition root is free to implement it over that facade. Bridging two features is the composition root's work; it is the one place where knowing both is the point.

## `LoadDirection` is a field, not two entities

The same arithmetic runs both ways and means opposite things. A parcel on the manifest that nobody scanned is *missing* when loading and *delivered or still aboard* when unloading. The sums are identical and the sentence a dispatcher reads is not, so the direction has to survive into the record.

## What it may depend on

`core_kernel`, `identity_api`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. Two identifiers cross; `ShipmentSummary` does not.

## What must never live here

- **An implementation of either driven port.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **A stored `missing` or `unexpected`.** See above.
- **A rule that refuses to close a count.** See above.

## Code generation

None.
