import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// A `GeoFencePort` a test puts the courier wherever it needs them.
///
/// Pushed by hand rather than simulated, so that a test about starting an
/// attempt three streets away is a statement rather than a coordinate
/// calculation somebody has to check.
///
/// The default is *at the door*. Most tests are about something else, and a
/// fixture that had to be moved into position before every one of them would
/// bury the tests that are genuinely about the fence.
final class FakeGeoFence implements GeoFencePort {
  /// How far the operation is prepared to accept.
  double allowedMetres = 100;

  /// Where the courier is, in metres from the address.
  double metresAway = 5;

  /// The identifiers this fence was asked about, in order.
  final List<String> asked = [];

  final List<DeliveryFailure> _queuedFailures = [];

  /// Puts the courier [metres] from the address.
  ///
  /// A method rather than a setter, so that it reads as the test arranging a
  /// situation rather than as part of the port it is standing in for.
  // ignore: use_setters_to_change_properties
  void standAt(double metres) => metresAway = metres;

  /// Makes the next call return [failure].
  ///
  /// The case worth using it for is `positionUnavailable`: a device that
  /// cannot see where it is calls for something different from a device that
  /// can see it is in the wrong street.
  void failNextWith(DeliveryFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<GeoFenceVerdict, DeliveryFailure>> locate(
    String shipmentId,
  ) async {
    asked.add(shipmentId);

    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    return Success(
      GeoFenceVerdict(
        isInside: metresAway <= allowedMetres,
        metresAway: metresAway,
        allowedMetres: allowedMetres,
      ),
    );
  }

  DeliveryFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
