import 'package:core_ports/src/network_condition.dart';

/// Reports whether the device can reach the network, and how.
///
/// Reading connectivity cannot fail — the answer to "are we offline?" when the
/// subsystem is unreachable is [NetworkCondition.offline], not an error. That
/// is why nothing here returns a `Result`.
///
/// Knowing the condition is not the same as knowing a request will succeed.
/// Adapters still handle failure; this port is what lets `sync` decide whether
/// attempting is worth it at all.
abstract interface class NetworkStatus {
  /// The condition as last observed.
  NetworkCondition get current;

  /// Emits whenever the condition changes.
  ///
  /// Implementations emit the current value on subscription, so a listener
  /// does not have to read [current] and subscribe separately and risk missing
  /// a change between the two.
  Stream<NetworkCondition> changes();
}
