# device_permissions

The `permission_handler`-backed adapter for the `PermissionRequester` port, and the durable record of what the user has already been asked.

## Why this package exists at all

The specification lists eight platform packages. This is the ninth, and the reason is that `PermissionRequester` has no natural owner among the other eight:

| Consumer | Permission it needs |
|---|---|
| `media_capture` | camera |
| `location_service` | location, when in use and always |
| `push_messaging` | notifications |

One plugin covers all three. Hosting the adapter inside any one of those packages would make the other two depend on it — and the constitution forbids `platform/*` depending on `platform/*` precisely so that cannot happen quietly. So the three consumers take the *port* through their constructors, and an application's composition root is where this adapter meets them.

The unusual thing is not the shape — every port in the workspace works this way — but that the port lives in `core_ports` while its adapter needed a package of its own.

## What it may depend on

`core_kernel`, `core_ports`, the Flutter SDK, `permission_handler` and `permission_handler_platform_interface`.

The adapter is written against the **platform interface**, not the plugin's top-level helpers, so a test can substitute an implementation instead of a method channel. `permission_handler` itself is still a dependency: it is what registers the Android and iOS implementations. It does not re-export the interface, and `depend_on_referenced_packages` is an error here, so both appear in the pubspec.

## What must never live here

- **Any decision about *whether* to ask.** Explaining why the camera is needed, and when, is a presentation concern. This package answers questions; it does not choose when they are worth asking.
- **A permission the product does not use.** The plugin knows about thirty-five. The port names four. Keeping the mapping exhaustive over the port's four is what stops a feature from requesting Bluetooth because the plugin happened to offer it.
- **A `Result`.** A denied permission is not a failure — it is an outcome the product has to design for. That is the port's decision and this package inherits it.

## The gap this adapter fills

`permission_handler` has no equivalent of `PermissionState.notDetermined`. On iOS, a permission that has never been asked for reports as `denied` — the same answer the platform gives for one the user actively refused.

The difference matters to the product. "Never asked" is a moment to explain and then prompt; "refused" is a moment to offer a way around. Collapsing them produces the rationale screen a courier sees every single day after saying no once.

So the adapter earns the state the platform will not give it. It records every permission it has asked for in the injected `KeyValueStore`, and reports `notDetermined` when the platform says `denied` for one it has no record of asking. The record is durable because a memory of what the user was asked has to survive a restart to be worth anything.

**When the record cannot be read, the adapter reports `denied`.** That is the conservative direction: claiming `notDetermined` would prompt again for something already refused, and on iOS the second prompt is never shown — so the courier would reach a button that does nothing. When the record cannot be *written*, the request still answers: losing the record costs one extra rationale screen, while failing the request would cost the capability itself.
