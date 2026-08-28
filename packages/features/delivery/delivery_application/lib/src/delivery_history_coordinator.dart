import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'attempt_reads.dart';
import 'delivery_channel.dart';

/// `DeliveryHistory`'s implementation: what happened at an address.
///
/// A read and a stream, and the whole of what a desk needs from delivery. The
/// read goes to the gateway rather than to the queue, because the answer to
/// "what happened to this parcel" includes visits made by somebody else's
/// device.
final class DeliveryHistoryCoordinator implements DeliveryHistory {
  /// Creates the coordinator over its use case.
  DeliveryHistoryCoordinator({
    required this._reads,
    required this._channel,
  });

  final AttemptReads _reads;
  final DeliveryChannel _channel;

  @override
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    ShipmentId shipment,
  ) => _reads(shipment);

  @override
  Stream<DeliveryAttempt> changes() => _channel.attempts;
}
