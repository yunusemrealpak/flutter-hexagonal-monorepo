/// What the device can currently do with the network.
///
/// Deliberately three states rather than a boolean. `app_courier` is
/// offline-first and treats a metered connection differently from an
/// unmetered one: photo evidence waits for wifi while a delivery confirmation
/// does not.
enum NetworkCondition {
  /// No usable connection. Work is queued rather than attempted.
  offline,

  /// Connected over a link the user pays for by volume.
  metered,

  /// Connected over a link with no per-byte cost to the user.
  unmetered,
}
