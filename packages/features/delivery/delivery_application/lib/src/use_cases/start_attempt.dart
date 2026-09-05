import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// What a caller wants attempted.
typedef StartRequest = ({
  ShipmentId shipment,
  ActorId courier,
  DeliveryGrade grade,
});

/// Opens an attempt, once the courier is actually at the address.
///
/// **The geofence is asked before anything is written down.** A delivery
/// recorded from three streets away is worse than no record: it is a record
/// that looks like evidence and is not, and an operation cannot tell the two
/// apart afterwards. Refusing here costs a courier one message; accepting
/// costs a dispute.
///
/// The port answers with a distance rather than a verdict about what to do,
/// and this use case is where the distance becomes a decision. That split is
/// why `app_dispatcher` can bind an adapter that always answers *inside* —
/// recording a hand-over the office was told about by telephone — without this
/// rule changing anywhere.
///
/// `positionUnavailable` is not `outsideDeliveryArea`, and both stop the
/// attempt. "I cannot see where you are" and "you are three streets away" send
/// a courier to different places, and a use case that collapsed them would
/// either block every delivery in a basement or accept them from the depot.
///
/// The identifier comes from `IdGenerator` and the instant from `Clock` —
/// rules A1 and A3. It is minted here, once, and every later retry of the same
/// intention carries it, which is what lets a server recognise the second copy
/// of one delivery.
final class StartAttempt
    implements UseCase<StartRequest, Result<DeliveryAttempt, DeliveryFailure>> {
  /// Creates the use case.
  const StartAttempt({
    required this._fence,
    required this._clock,
    required this._ids,
  });

  final GeoFencePort _fence;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> call(
    StartRequest request,
  ) async {
    final GeoFenceVerdict verdict;
    switch (await _fence.locate(request.shipment.value)) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final value):
        verdict = value;
    }

    if (!verdict.isInside) {
      return Failed(
        OutsideDeliveryArea(
          metresAway: verdict.metresAway,
          allowedMetres: verdict.allowedMetres,
        ),
      );
    }

    return DeliveryAttemptId.parse(_ids.newId()).map(
      (id) => DeliveryAttempt.started(
        id: id,
        shipment: request.shipment,
        courier: request.courier,
        startedAt: _clock.now(),
        grade: request.grade,
      ),
    );
  }
}
