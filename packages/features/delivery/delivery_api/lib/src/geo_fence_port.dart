import 'package:core_kernel/core_kernel.dart';

import 'delivery_failure.dart';
import 'geo_fence_verdict.dart';

/// Answers whether the courier is actually at the address.
///
/// A driven port, and the shape of it is the interesting part. It takes a
/// shipment identifier and returns a distance — **no coordinates cross this
/// interface in either direction**, and that is not squeamishness. A latitude
/// and a longitude in this file would mean delivery had to declare a point
/// type of its own or borrow shipments' `AddressPoint`; the first is a third
/// spelling of a coordinate in one workspace, the second is the model-crossing
/// section 2.1 forbids. Asking the question delivery actually has — *am I
/// there yet* — avoids both.
///
/// It also puts the two halves of the answer in the adapter, where they
/// belong: where the device is, and where the parcel is going. Neither is a
/// domain fact, both are lookups, and `delivery_application` may not depend on
/// `platform/*` to do either.
///
/// The identifier arrives raw. A driven port is implemented by an adapter, an
/// adapter may see no foreign `_api`, and a signature naming `ShipmentId`
/// would be one its own adapter could not write down.
abstract interface class GeoFencePort {
  /// Where the courier is standing, relative to where [shipmentId] is going.
  Future<Result<GeoFenceVerdict, DeliveryFailure>> locate(String shipmentId);
}
