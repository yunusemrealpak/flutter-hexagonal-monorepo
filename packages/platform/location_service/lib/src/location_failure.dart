import 'package:core_kernel/core_kernel.dart';

/// Why a position could not be produced.
///
/// Five cases, and each one leads somewhere different in the interface: turn
/// the device's location services on, grant the permission, open system
/// settings, wait and try again, or report a fault. A hierarchy that collapsed
/// any two of them would produce a screen that tells a courier to do something
/// that will not help.
sealed class LocationFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const LocationFailure();
}

/// Location services are switched off on the device.
///
/// Nothing about the app can fix this, and the permission state is irrelevant
/// while it holds — which is why it is checked first.
final class LocationServicesDisabled extends LocationFailure {
  /// Records that the device's location services are off.
  const LocationServicesDisabled();

  @override
  String toString() => 'LocationServicesDisabled()';
}

/// The user has not granted location access, and can still be asked.
final class LocationPermissionDenied extends LocationFailure {
  /// Records that permission was refused, with asking still possible.
  const LocationPermissionDenied();

  @override
  String toString() => 'LocationPermissionDenied()';
}

/// The user has refused location access in a way that stops the app asking
/// again, or device policy forbids it.
///
/// Separate from [LocationPermissionDenied] because the only remaining route
/// is the system settings screen. Prompting again shows nothing at all on iOS,
/// so an app that could not tell these apart would offer a button that does
/// nothing.
final class LocationPermissionBlocked extends LocationFailure {
  /// Records that permission cannot be requested again from inside the app.
  const LocationPermissionBlocked();

  @override
  String toString() => 'LocationPermissionBlocked()';
}

/// No fix arrived within the time allowed.
///
/// Ordinary indoors and underground, and not a fault: the caller is expected
/// to retry, fall back to a coarser accuracy, or carry on without a position.
final class LocationTimeout extends LocationFailure {
  /// Records that no fix arrived within [waited].
  const LocationTimeout(this.waited);

  /// How long the adapter waited before giving up.
  final Duration waited;

  @override
  String toString() => 'LocationTimeout($waited)';
}

/// The platform failed for a reason none of the other cases describes.
final class LocationUnavailable extends LocationFailure {
  /// Records an unclassified failure, with [detail] for the log.
  const LocationUnavailable({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'LocationUnavailable($detail)';
}
