@Tags(['unit'])
library;

import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

/// The fakes are held to the same suite as the adapters.
///
/// This file is three lines and is the reason the fakes can be trusted. The
/// same two functions are called from `shipments_infrastructure`'s tests
/// against `RestShipmentGateway` and the Drift-backed cache; if either side
/// ever answers differently, one of the two runs goes red.
void main() {
  runShipmentGatewayContract(InMemoryShipmentGateway.new);
  runShipmentCacheContract(InMemoryShipmentCache.new);
}
