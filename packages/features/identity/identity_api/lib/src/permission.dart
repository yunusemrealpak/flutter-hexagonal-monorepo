/// One thing an actor is allowed to do.
///
/// Permissions are named after the action, not after the screen that offers it
/// and not after the role that usually holds it. `bulkAssignShipments` outlives
/// the dispatcher table it was introduced for; `dispatcherScreen` would not,
/// and the day a supervisor needed the same action the check would have to be
/// rewritten everywhere it was made.
///
/// An enum rather than a string. A typo in a string permission is a permission
/// nobody holds, which fails open in the one direction that matters: the check
/// passes silently in the code that grants and fails silently in the code that
/// asks.
enum Permission {
  /// See the shipments assigned to oneself.
  viewAssignedShipments,

  /// See every shipment in the operation, assigned or not.
  viewAllShipments,

  /// Move one shipment onto a courier's manifest.
  assignShipment,

  /// Move many shipments onto couriers' manifests in a single action.
  ///
  /// Separate from [assignShipment] on purpose. The blast radius of the two is
  /// different by an order of magnitude, and scenario 6 of the architecture —
  /// a presentation package asking `PermissionChecker` before it renders the
  /// bulk-assign button — is about exactly this one.
  bulkAssignShipments,

  /// Record a delivery attempt and its proof.
  completeDelivery,

  /// Take money at the door.
  collectPayment,

  /// Return money that was taken.
  refundPayment,

  /// File a damage, address-not-found or recipient-absent report.
  reportIncident,

  /// Read operational metrics across couriers.
  viewReports,

  /// Change the settings that affect other people.
  manageSettings,
}
