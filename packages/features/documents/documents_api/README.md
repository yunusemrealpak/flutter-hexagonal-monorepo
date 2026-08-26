# documents_api

The documents contract: the paperwork a round produces, where it is kept, and what it costs to produce it twice.

## `DocumentId` is derived, and that is the caching story

`waybill:SHP-42` is the same document however many times somebody asks for it, so the archive can answer the second request without spending a courier's data allowance on a second render.

The cost of that choice is real and is written into the rest of the design: a template change produces no new identifier, so the archive **evicts** rather than keeping documents for ever, and `DocumentsFacade.refresh` exists for the person who knows something the cache cannot.

Compare `IncidentId` and `LoadCountId`, both minted: a parcel can go wrong twice and a van is counted twice a day, so deriving those would make the second record overwrite the first. A document has no such history — there is one current waybill.

## A document carries its bytes

One that carried a URL would stop existing when the signal did, and the reason a courier opens a document is usually that somebody at a door is asking to see it.

The bytes are a `List<int>` rather than a `Uint8List`: the adapter that produces them converts once, and nothing else in the feature has to know about `dart:typed_data`.

## There is no `share` on the facade

Sharing is a platform capability with no `platform/*` package behind it yet. A `share` here would be a port whose adapter could not live in this feature — so the app supplies a callback to the screen instead, exactly as `delivery_presentation` takes the camera.

## The archive is a cache with a promise

Everything in it can be produced again, which is what makes eviction safe and why `DocumentMissing` is an *ordinary* outcome rather than a fault. The eviction policy belongs to the adapter: a phone evicts on count, a dispatcher's workstation might not evict at all.

## What it may depend on

`core_kernel`, `shipments_api`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row. One identifier crosses. This is the only feature in phase 6 that needs no `identity_api`: paperwork belongs to a parcel, not to a person.

## What must never live here

- **An implementation of either port.** Rule S8.
- **A DTO, or `json_annotation`.** Rules I4 and G2.
- **A `share`.** See above.
- **A rule about which documents are legally required.** That is the operation's, and it changes without a release; the renderer refuses what it will not produce.

## Code generation

None.
