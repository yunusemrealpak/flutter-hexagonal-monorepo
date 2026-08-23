# location_service

The location contract every feature that needs a position talks to, its `geolocator`-backed adapter, and the fake that keeps tests off the GPS.

## What it is for

| Type | Role |
|---|---|
| `LocationSource` | the contract: a fix, or a `Result` saying why not |
| `GeolocatorLocationSource` | the only file in the workspace that imports geolocator |
| `FakeLocationSource` | a programmable source, so no test waits for a satellite |
| `GeoFix`, `FixAccuracy`, `sealed LocationFailure` | the vocabulary they share |

## Why the contract lives here and not in `core_ports`

Same reason as `HttpTransport` in `http_dio`: nothing in the product asks for "a GPS fix". `delivery` asks whether a courier is at the consignee's address; `routing` asks how far along a route they are. Those are ports in those features' own `_api` packages, and their `_infrastructure` answers them using this.

`GeoFix` is deliberately not a domain type either. The features that need coordinates declare their own, with their own invariants — a proof-of-delivery location that must be within a tolerance of an address, a waypoint that must be on a road — and map this into them. That is the same DTO-to-entity discipline rule 1.2.10 asks for at every other boundary.

## What it may depend on

`core_kernel`, `core_ports`, the Flutter SDK, `geolocator` and `geolocator_platform_interface`.

## What must never live here

- **A geofence check, a distance calculation, or a route.** Those are domain rules that belong to `delivery` and `routing`. This package produces positions; it does not judge them.
- **A permission adapter.** See below.
- **A retry policy.** The failure cases say what happened; deciding to try again is the caller's.

## Permission arrives through the port, not through the plugin

`geolocator` has its own permission API. This adapter ignores it and takes `core_ports.PermissionRequester` through its constructor. Two reasons, and the second is the architectural one:

- **One mechanism.** An app that asks for location through geolocator and for the camera through permission_handler has two places where "have we asked yet?" is answered, and they disagree the first time somebody changes one.
- **No `platform/*` → `platform/*` edge.** The real permission adapter lives in `device_permissions`. Depending on it directly is exactly what the constitution forbids; depending on the *port* it implements, and letting the composition root join them, is what obeying that rule looks like when two platform packages genuinely need each other.

## Three decisions worth knowing about

**Services are checked before permission.** A device with location switched off refuses regardless of what the user granted, so prompting first produces a dialog that cannot help — and on iOS it spends the one chance to ask.

**A blocked permission is its own failure case.** `LocationPermissionDenied` can be asked again; `LocationPermissionBlocked` cannot, and the only remaining route is the system settings screen. An app that could not tell them apart would offer a button that does nothing.

**`track()` yields failures instead of ending on them.** A courier who walks into a car park loses signal and gets it back. A stream that closed on the first failure would leave the rest of the shift untracked, and the fix that matters is usually the next one.
