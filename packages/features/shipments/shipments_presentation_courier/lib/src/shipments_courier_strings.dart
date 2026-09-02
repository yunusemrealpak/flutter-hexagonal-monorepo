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

  /// The action that fetches the next page of stops.
  static const String loadMore = 'shipments.courier.loadMore';

  /// Shown when the next page did not arrive and the ones before it did.
  static const String moreFailed = 'shipments.courier.moreFailed';

  /// The key for one shipment status.
  ///
  /// Shared with the dispatcher package by spelling, not by import: a
  /// presentation package may not depend on another presentation package, so
  /// the two declare the same key and an app answers it once. That is a real
  /// cost of the boundary and it is cheaper than the alternative.
  static String status(ShipmentStatus status) =>
      'shipments.status.${status.label}';

  /// Every status key this screen can ask for.
  ///
  /// Written out rather than derived, because `ShipmentStatus` is a `freezed`
  /// union and has no `values` to walk. The test beside this file exhausts the
  /// union in a `switch`, so adding a state stops that test compiling — the
  /// same guarantee an enum would have given, bought with one test.
  ///
  /// **`shipments_presentation_dispatcher` declares the identical seven.**
  /// That duplication is the price of section 2's rule that a presentation
  /// package may not depend on another, and phase 7 is where the price came
  /// due: `app_courier` mounts this package and not that one, so a manifest
  /// that pointed at the dispatcher's list would have left a courier's status
  /// chips unanswered — which is exactly what that app's catalogue coverage
  /// test reported.
  static const List<String> statusKeys = [
    'shipments.status.awaitingAssignment',
    'shipments.status.assignedToCourier',
    'shipments.status.loadedOnVehicle',
    'shipments.status.outForDelivery',
    'shipments.status.deliveredToConsignee',
    'shipments.status.undeliverable',
    'shipments.status.returnedToDepot',
  ];

  /// Every key above, for an app's coverage test.
  static const List<String> all = [
    title,
    empty,
    loadMore,
    moreFailed,
    failureUnavailable,
    failureNotFound,
    failureOther,
    ...statusKeys,
  ];
}
