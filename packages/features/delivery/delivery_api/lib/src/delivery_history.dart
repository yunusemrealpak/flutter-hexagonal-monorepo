import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import 'delivery_attempt.dart';
import 'delivery_failure.dart';

/// What has already been tried at an address.
///
/// The read half, and the only part of delivery a desk needs to be useful. It
/// carries the change stream because watching for a settled attempt is a read:
/// whichever role wrote the attempt, a screen holding this interface sees it.
abstract interface class DeliveryHistory {
  /// Every attempt recorded against [shipment], oldest first.
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    ShipmentId shipment,
  );

  /// Emits an attempt whenever one is opened or settled.
  Stream<DeliveryAttempt> changes();
}
