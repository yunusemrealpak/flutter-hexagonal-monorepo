import 'package:shipments_api/shipments_api.dart';

/// Every string key this package asks an app to answer.
///
/// The status keys are built from `ShipmentStatus.label`, which is a stable
/// name and explicitly not a localisation key — `shipments_api`'s own doc
/// comment says a contract package should not own one. This is where the name
/// becomes a key, in the package that has an app to ask.
abstract final class ShipmentsCourierStrings {
  /// The manifest screen's title.
  static const String title = 'shipments.courier.title';

  /// Shown when nothing has been assigned yet.
  ///
  /// Not an error. An empty manifest is an ordinary morning, and a failure
  /// here would have couriers calling the depot before their first parcel.
  static const String empty = 'shipments.courier.empty';

  /// There is no signal, so this list came off the device.
  static const String failureUnavailable =
      'shipments.courier.failure.unavailable';

  /// The shipment is no longer in the operation.
  static const String failureNotFound = 'shipments.courier.failure.notFound';

  /// Anything else shipments can fail with.
  static const String failureOther = 'shipments.courier.failure.other';

  /// The key for one shipment status.
  ///
  /// Shared with the dispatcher package by spelling, not by import: a
  /// presentation package may not depend on another presentation package, so
  /// the two declare the same key and an app answers it once. That is a real
  /// cost of the boundary and it is cheaper than the alternative.
  static String status(ShipmentStatus status) =>
      'shipments.status.${status.label}';

  /// Every key above, for an app's coverage test.
  ///
  /// The status keys are not in it: `ShipmentStatus` is a `freezed` union
  /// rather than an enum, so there is no `values` to walk. The dispatcher
  /// package's manifest carries them, built from the seven constructors by
  /// hand, and a `switch` in its test is what keeps that list honest.
  static const List<String> all = [
    title,
    empty,
    failureUnavailable,
    failureNotFound,
    failureOther,
  ];
}
