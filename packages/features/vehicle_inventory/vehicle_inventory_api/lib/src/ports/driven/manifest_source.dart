import 'package:core_kernel/core_kernel.dart';

import '../../failures/vehicle_inventory_failure.dart';

/// What the depot says should be in a courier's van.
///
/// A driven port. It answers with **raw identifiers**, not `ShipmentId`s, for
/// the reason `docs/DEPENDENCY_RULES.md` §2.1 gives: a driven port whose
/// signature names another feature is a port its own adapter cannot implement
/// without depending on that feature. Reading them into `ShipmentId`s is the
/// use case's job, and the parse failure it can produce is part of why this
/// feature has a `MalformedCount` case.
///
/// **It is not `ShipmentsFacade`.** Shipments already answers "what is on this
/// courier's manifest", and consuming that directly would drag
/// `ShipmentSummary` — an address, a consignee, a status — into a feature
/// whose entire job is counting. An app's composition root is free to
/// implement this port over that facade; that is the composition root's work,
/// and it is the one place where knowing both features is the point.
abstract interface class ManifestSource {
  /// The identifiers the depot expects in [courierId]'s van.
  Future<Result<List<String>, VehicleInventoryFailure>> manifestFor(
    String courierId,
  );
}
