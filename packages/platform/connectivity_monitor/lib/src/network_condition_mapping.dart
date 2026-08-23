import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:core_ports/core_ports.dart';

/// What the product can afford to do over the transports in [results].
///
/// The plugin reports *transports*; the port declares *affordances*. That gap
/// is the whole reason this function exists, and it is where a decision about
/// the product gets made rather than a decision about the network.
///
/// `NetworkCondition` has three values instead of a boolean because
/// `app_courier` is offline-first and treats a link the user pays for by
/// volume differently from one they do not: photo evidence waits for wifi
/// while a delivery confirmation does not. Collapsing metered and unmetered
/// would either upload evidence over cellular in a rural shift or hold back a
/// confirmation the dispatcher is waiting for.
///
/// Three mappings are judgement calls rather than facts:
///
/// - **`satellite` is metered**, and is reported alongside `mobile`. It is a
///   highly constrained link; anything large sent over it is worse than
///   waiting.
/// - **`bluetooth` and `other` are metered.** The plugin cannot say what they
///   cost, and the expensive assumption is the safe one: treating an unknown
///   link as free is how a courier ends up paying for a photo upload.
/// - **`vpn` alone is unmetered.** On iOS and macOS a VPN masks the underlying
///   transport entirely, so there is nothing better to go on. Where the
///   platform does report both, the underlying transport decides.
NetworkCondition toNetworkCondition(List<ConnectivityResult> results) {
  if (results.isEmpty ||
      results.every((result) => result == ConnectivityResult.none)) {
    return NetworkCondition.offline;
  }
  // Metered wins over unmetered when both appear: a device on wifi and
  // cellular at once may fall back to cellular mid-transfer, and the cost of
  // being wrong in that direction is somebody's data allowance.
  const metered = {
    ConnectivityResult.mobile,
    ConnectivityResult.satellite,
    ConnectivityResult.bluetooth,
    ConnectivityResult.other,
  };
  if (results.any(metered.contains)) {
    return NetworkCondition.metered;
  }
  return NetworkCondition.unmetered;
}
