# core_navigation

Route contracts shared by presentation packages and assembled by an app.

## What it is for

| Type | What it is |
|---|---|
| `RouteLocation` | A concrete destination. A `ValueObject` over the encoded location string, so two locations built the same way compare equal. |
| `RouteDefinition` | One destination a feature offers: name, path pattern, whether a session is required, and which permission it needs. |
| `RouteModule` | What a `_presentation` package exposes so an app can mount its screens. |

## What it may depend on

`core_kernel`, and nothing else. In particular **not** Flutter and **not** a router library. That absence is the whole point: `shipments_presentation_courier` declares where it can be reached without knowing whether it ended up in `app_courier` or `app_harness`, or what that app routes with.

## What must never live here

- **Widgets, or anything that renders.** This package describes destinations; drawing them is `design_system` and the presentation packages.
- **Router library types.** `go_router` appears in the apps and, through generated code, in presentation packages. A `GoRoute` here would make every feature depend on that choice.
- **Guard logic.** `RouteDefinition` states that a destination needs `shipments.assign`; deciding whether the current actor holds it is the app's guard asking identity's `PermissionChecker`.
- **Generated code.** No `build_runner` dependency and no `build.yaml`.

## Three decisions worth reading

**There is no `Navigation` port here, and its absence is deliberate.** One existed until it was deleted: `goTo`, `replaceWith`, `back`, held by a presentation package and adapted by an app. It is the design `DEPENDENCY_RULES.md` §2.4 examined and rejected — a port that navigates has to name destinations, so either it names every feature's routes (which is `shared` wearing a router's clothes) or it takes an unchecked string. A screen reports an outcome; the app decides the destination. `RouteLocation` survives because describing a destination and deciding to go there are different jobs.

**Query parameters are sorted before encoding.** Navigation is routinely deduplicated — a double tap must not push the same screen twice — and that check is a value comparison. Without sorting, the same destination built from two differently ordered maps would compare unequal and the deduplication would silently stop working.

**`requiredPermission` is a plain string.** `core_navigation` may not depend on `identity_api`, and should not want to. It states the requirement; the app resolves it against the `PermissionChecker` identity exposes. This is scenario 6 of the architecture expressed at the route level instead of inside a widget.
