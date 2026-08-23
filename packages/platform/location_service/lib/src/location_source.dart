import 'package:core_kernel/core_kernel.dart';
import 'fix_accuracy.dart';
import 'geo_fix.dart';
import 'location_failure.dart';

/// Produces device positions, without throwing.
///
/// A technology contract, like `HttpTransport` in `http_dio`, and declared
/// here for the same reason: `core_ports` holds capabilities the product asks
/// for in the product's own words, and nothing in the product asks for "a GPS
/// fix". `delivery` asks whether a courier is at the consignee's address;
/// `routing` asks how far along a route they are. Those are ports in those
/// features' own `_api` packages, and their `_infrastructure` answers them
/// using this.
///
/// Every method returns a `Result`, including the stream — a position source
/// can lose permission, lose signal, or be switched off halfway through a
/// shift, and none of those may reach a caller as an exception. A stream that
/// closed on the first failure would be worse than useless to a courier app:
/// the fix that matters is usually the next one.
abstract interface class LocationSource {
  /// One position, now.
  ///
  /// Gives up after [timeout] with [LocationTimeout], which is ordinary
  /// indoors and underground rather than a fault.
  Future<Result<GeoFix, LocationFailure>> currentFix({
    FixAccuracy accuracy,
    Duration timeout,
  });

  /// Positions as the device moves.
  ///
  /// Emits at most one fix per [distanceFilterMetres] of movement, which is
  /// what keeps a shift-long subscription from flattening the battery.
  ///
  /// [inBackground] decides which permission is required: tracking that
  /// continues while the app is backgrounded needs the "always" grant, and
  /// asking for it when it is not needed is how an app gets a permission
  /// request refused for the wrong reason.
  Stream<Result<GeoFix, LocationFailure>> track({
    FixAccuracy accuracy,
    int distanceFilterMetres,
    bool inBackground,
  });
}
