/// The connectivity_plus-backed adapter for the `NetworkStatus` port.
///
/// The package is small and the one idea in it is the gap between what the
/// plugin reports and what the port declares. `connectivity_plus` answers with
/// *transports* — wifi, mobile, vpn, satellite. `NetworkCondition` answers with
/// *affordances* — offline, metered, unmetered. Translating one into the other
/// is a decision about the product, not about the network, and
/// `toNetworkCondition` is where that decision is written down and tested.
///
/// The three-value condition earns its existence in `app_courier`, which is
/// offline-first: photo evidence waits for an unmetered link while a delivery
/// confirmation does not. A boolean would either upload evidence over cellular
/// during a rural shift or hold back a confirmation a dispatcher is waiting
/// for.
library;

export 'src/connectivity_monitor.dart';
export 'src/network_condition_mapping.dart';
