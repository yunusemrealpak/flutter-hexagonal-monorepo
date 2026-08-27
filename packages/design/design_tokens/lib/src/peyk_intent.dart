/// What a piece of the interface is telling somebody, independent of what it
/// is telling them *about*.
///
/// This is the vocabulary the design layer offers instead of a colour name. A
/// presentation package maps its own states onto it — a delivered shipment is
/// [success], an overdue incident is [danger] — and the mapping stays in the
/// feature that owns the state. Naming these `delivered` or `overdue` here
/// would put a courier product's domain inside a package whose whole job is to
/// have no idea what the product does.
enum PeykIntent {
  /// Nothing is being claimed. The default for text and containers.
  neutral,

  /// Something is worth reading but nothing is wrong.
  info,

  /// Something finished the way it was supposed to.
  success,

  /// Something needs a person's attention but has not failed.
  warning,

  /// Something failed, or is about to.
  danger,
}
