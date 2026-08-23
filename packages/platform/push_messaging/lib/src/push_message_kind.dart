/// What a push is about, as far as the product is concerned.
///
/// The provider's payload is a string map with no schema. This enum is the
/// product's schema for it, and the reason it exists is that a switch over a
/// closed set is checked by the compiler while a chain of string comparisons
/// scattered across three presentation packages is not.
enum PushMessageKind {
  /// A shipment has been assigned to the courier receiving this.
  shipmentAssigned,

  /// A dispatcher has sent a message on a shipment's thread.
  dispatchMessage,

  /// The courier's route has been recalculated.
  routeUpdated,

  /// Something the product does not recognise.
  ///
  /// Never dropped and never an error. A server that starts sending a new kind
  /// before this app version knows about it is normal — a fleet updates over
  /// weeks — and an app that crashed or silently discarded the message would
  /// be worse than one that ignores it knowingly.
  unknown,
}
