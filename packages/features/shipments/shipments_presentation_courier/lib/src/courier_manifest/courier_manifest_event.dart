/// What can happen to the courier's stop list.
sealed class CourierManifestEvent {
  const CourierManifestEvent();
}

/// Fetch the manifest from the beginning.
final class ManifestRequested extends CourierManifestEvent {
  /// Creates the event.
  const ManifestRequested();
}

/// Fetch the page after the one on screen.
final class MoreRequested extends CourierManifestEvent {
  /// Creates the event.
  const MoreRequested();
}
