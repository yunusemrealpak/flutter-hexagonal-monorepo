# documents_core

The documents use cases, the renderer that produces paperwork over HTTP, and the archive that keeps a device from filling with it.

## Rendering happens on the server

A waybill is a legal document whose layout changes when the operation's terms do. Rendering it on a phone would mean every courier carrying a version of the template, and a fleet that updates over weeks would produce weeks of documents that disagree with each other.

The bytes come back base64-encoded inside JSON because `HttpTransport` answers with a decoded body rather than a stream. That is the transport's shape and this adapter's problem: it decodes once, and nothing else in the feature knows.

## Two failures, because two things are worth telling a courier

A 4xx is the operation saying this document does not exist and will not — a receipt for a delivery that has not happened — and the courier deserves that sentence rather than a spinner. Everything else is `RenderFailed` and worth asking again.

## The cap is the point of the archive

A courier's phone is not where a year of PDFs belongs, and an archive without a cap becomes a support call about storage three months after launch.

Eviction is by **render order**, not by last use. A least-recently-used policy needs a write on every read, which on a phone is a write every time somebody glances at a document; the parcel somebody is asking about today was rendered today, so render order is a good enough proxy and costs nothing.

## Neither cache failure reaches a courier

- An archive that **cannot be read** does not stop a render. A device whose cache is broken should still be able to show somebody a waybill.
- An archive that **cannot be written** does not fail the answer. The document was produced and somebody is holding out a phone; failing here would turn a full disk into a document nobody can see.
- A **corrupt** archive is treated as an empty one. This is the only place in phase 6 where a corrupt store is not reported, and the reason is that this store is the only one whose contents can be produced again — every other feature's stored state is the only copy there is.

All three are logged. A cache failing silently every time is a bug somebody should see.

## What it may depend on

`core_kernel`, `core_ports`, `documents_api`, `shipments_api`, `http_dio`

That list is section 2 of [`docs/DEPENDENCY_RULES.md`](../../../../docs/DEPENDENCY_RULES.md), one row.

## What must never live here

- **An import between the two halves.** `HttpDocumentRenderer` and `CappedDocumentArchive` import no use case; no use case imports them.
- **A PDF library.** Rendering is the server's, for the reason above — and a phone-side renderer would be the second implementation of a legal document.
- **`DateTime.now()`.** Rule A1; the render instant is what eviction order is decided by.

## Code generation

None.
