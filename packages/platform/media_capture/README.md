# media_capture

The photo-evidence contract, its `image_picker`-backed adapter, and the fake that lets a delivery flow be tested without a camera.

## What it is for

| Type | Role |
|---|---|
| `MediaCapture` | the contract: one method, `capturePhoto` |
| `ImagePickerMediaCapture` | the only file in the workspace that imports image_picker |
| `FakeMediaCapture` | a programmable capture, so no test needs a device |
| `CapturedMedia`, `sealed CaptureFailure` | the vocabulary they share |

## Why one method

Every extra capture mode — video, gallery selection, multiple images — carries its own permission story, its own size story and its own compression story. The product needs exactly one of them today. A contract offering five would be five things to fake, five to test, and four that nothing calls.

The contract is also a technology contract rather than a domain one, and it lives here for the same reason `HttpTransport` lives in `http_dio`: nothing in the product asks for "a photo". `delivery` asks for proof that a parcel reached a consignee, and its `_infrastructure` answers that using this.

## What it may depend on

`core_kernel`, `core_ports`, the Flutter SDK, `image_picker` and `image_picker_platform_interface`.

Permission arrives through `core_ports.PermissionRequester`, not through the plugin — one mechanism for the whole app, and no `platform/*` → `platform/*` edge to `device_permissions`. `Clock` arrives the same way, because the platform does not timestamp a capture and reading the system clock would make every assertion about `capturedAt` approximate.

## What must never live here

- **What counts as valid evidence.** `delivery` declares its own proof entity, with its own rules, and maps `CapturedMedia` into it.
- **Upload, storage or retention.** This package produces a file on disk. Where it goes is `sync`'s and `delivery_infrastructure`'s business.
- **Image processing.** Downscaling is handed to the platform as instructions, not done here afterwards.

## Two decisions worth knowing about

**`CapturedMedia` carries a path, not bytes.** Proof-of-delivery photos are megabytes each, a courier takes dozens in a shift, and holding them in memory while an outbox drains is how an offline-first app gets killed by the operating system. `byteSize` is carried alongside so `sync` can decide whether the upload waits for an unmetered link without opening the file to find out.

**`CaptureCancelled` is a failure case that is not an error.** A courier who opens the camera and changes their mind is behaving normally. The case exists so a caller can tell "nothing happened" from "something broke" — and not show a red banner for the first. That distinction is the whole reason failure types in this workspace are `sealed` rather than a message string.
