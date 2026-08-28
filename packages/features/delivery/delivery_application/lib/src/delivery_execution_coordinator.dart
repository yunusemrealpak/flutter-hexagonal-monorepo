import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'delivery_channel.dart';
import 'start_attempt.dart';

/// `DeliveryExecution`'s implementation: standing at the door.
///
/// **The class a desk cannot build.** `StartAttempt` holds a `GeoFencePort`,
/// and that port asks whether *this device* is inside the delivery area. Until
/// phase 8 one coordinator took all four use cases, so `app_dispatcher` had to
/// supply this one — and the geofence adapter, and the GPS under it — to get
/// the read half of a feature it only reads.
final class DeliveryExecutionCoordinator implements DeliveryExecution {
  /// Creates the coordinator over its use case.
  DeliveryExecutionCoordinator({
    required this._startAttempt,
    required this._channel,
  });

  final StartAttempt _startAttempt;
  final DeliveryChannel _channel;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> startAttempt({
    required ShipmentId shipment,
    required ActorId courier,
    DeliveryGrade grade = DeliveryGrade.standard,
  }) => _channel.announce(
    _startAttempt((shipment: shipment, courier: courier, grade: grade)),
  );
}
