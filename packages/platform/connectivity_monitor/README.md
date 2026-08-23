# connectivity_monitor

The `connectivity_plus`-backed adapter for the `NetworkStatus` port.

## What it is for

| Type | Role |
|---|---|
| `ConnectivityMonitor` | implements `core_ports.NetworkStatus` |
| `toNetworkCondition` | transports → what the product can afford to do |

The one idea in the package is that gap. The plugin answers with **transports** — wifi, mobile, vpn, satellite. `NetworkCondition` answers with **affordances** — offline, metered, unmetered. Translating one into the other is a decision about the product, not about the network, and `toNetworkCondition` is where that decision is written down and tested.

The three-value condition earns its existence in `app_courier`, which is offline-first: photo evidence waits for an unmetered link while a delivery confirmation does not. A boolean would either upload evidence over cellular during a rural shift or hold back a confirmation a dispatcher is waiting for.

## What it may depend on

`core_ports`, the Flutter SDK, `connectivity_plus` and `connectivity_plus_platform_interface`. Not `core_kernel` — nothing here returns a `Result`, because reading connectivity cannot fail.

## What must never live here

- **A retry policy.** Knowing the condition is not the same as knowing a request will succeed. Adapters keep handling failure; this port only lets `sync` decide whether attempting is worth it at all.
- **A `Result`.** The answer to "are we offline?" when the subsystem is unreachable is `offline`, not an error.
- **Any use of the condition.** What waits for wifi is a decision for the feature that owns the work.

## Two decisions worth knowing about

**The adapter has a lifecycle the port does not.** `NetworkStatus.current` is synchronous, because `sync` reads it inside a loop and must not await. The plugin is asynchronous. So the adapter caches the last observed condition and refreshes it from the plugin's stream, which gives it a `start()` and a `dispose()` that only a composition root ever calls. Before `start()` completes, `current` is `offline` — the conservative direction, since a queued item that turns out to have been sendable costs seconds while an attempt with no connection costs a failed request and a retry schedule.

**`changes()` is built with `Stream.multi`, not an `async*` generator.** This is not style. A generator does not subscribe to what it delegates to until its first yielded value has been consumed, so a change arriving in that window is dropped by a broadcast source — which reintroduces exactly the gap the port's "emits the current value on subscription" promise exists to close. The first version of this adapter had that bug and two tests caught it. `Stream.multi` subscribes first and queues the seed value behind the subscription.

Changes are also deduplicated on the **mapped** value. The plugin emits for every transport change — gaining a VPN over the same wifi, for instance — and a listener woken for those would be woken for nothing.
