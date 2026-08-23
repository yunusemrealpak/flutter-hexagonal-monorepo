/// A capability the operating system guards behind the user's consent.
enum DevicePermission {
  /// Taking photo evidence at a delivery.
  camera,

  /// Reading position for route progress and geofenced proof of delivery.
  locationWhenInUse,

  /// Reading position while the app is backgrounded, for route tracking
  /// across a shift.
  locationAlways,

  /// Showing dispatch messages and assignment alerts.
  notifications,
}
