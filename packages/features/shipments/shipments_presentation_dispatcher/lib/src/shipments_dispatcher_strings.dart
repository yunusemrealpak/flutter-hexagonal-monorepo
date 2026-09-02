import 'package:shipments_api/shipments_api.dart';

/// Every string key this package asks an app to answer.
abstract final class ShipmentsDispatcherStrings {
  /// The board's title.
  static const String title = 'shipments.dispatcher.title';

  /// Shown when the operation has nothing on it.
  static const String empty = 'shipments.dispatcher.empty';

  /// The bulk-assign action. Takes a `count` argument.
  static const String bulkAssign = 'shipments.dispatcher.bulkAssign';

  /// The action that fetches the next page of the board.
  static const String loadMore = 'shipments.dispatcher.loadMore';

  /// Shown when the next page did not arrive and the ones before it did.
  static const String moreFailed = 'shipments.dispatcher.moreFailed';

  /// The board could not be loaded.
  static const String failureUnavailable =
      'shipments.dispatcher.failure.unavailable';

  /// The key for one shipment status.
  ///
  /// The same spelling `shipments_presentation_courier` uses, and shared by
  /// spelling rather than by import: a presentation package may not depend on
  /// another presentation package. Two declarations of one key is the price of
  /// that boundary, and `statusKeys` below is what stops them drifting.
  static String status(ShipmentStatus status) =>
      'shipments.status.${status.label}';

  /// Every status key the two shipments screens can ask for.
  ///
  /// Written out rather than derived, because `ShipmentStatus` is a `freezed`
  /// union and has no `values` to walk. The test beside this file exhausts the
  /// union in a `switch`, so adding a state stops that test compiling — which
  /// is the same guarantee an enum would have given, bought with one test
  /// instead of a type change.
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
    loadMore,
    moreFailed,
    title,
    empty,
    bulkAssign,
    failureUnavailable,
    ...statusKeys,
  ];
}
