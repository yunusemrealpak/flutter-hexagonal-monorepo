import 'package:core_kernel/core_kernel.dart';

/// Why no media was captured.
///
/// Four cases, and one of them is not an error at all — see
/// [CaptureCancelled].
sealed class CaptureFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const CaptureFailure();
}

/// The user has not granted camera access, and can still be asked.
final class CapturePermissionDenied extends CaptureFailure {
  /// Records that camera access was refused, with asking still possible.
  const CapturePermissionDenied();

  @override
  String toString() => 'CapturePermissionDenied()';
}

/// Camera access is refused in a way the app cannot ask about again, or device
/// policy forbids it.
final class CapturePermissionBlocked extends CaptureFailure {
  /// Records that camera access cannot be requested again from inside the app.
  const CapturePermissionBlocked();

  @override
  String toString() => 'CapturePermissionBlocked()';
}

/// The user opened the camera and backed out without taking a photo.
///
/// A `Result` failure because the method has to return something and there is
/// no media — but not an error, and never something to report. A courier who
/// changes their mind is behaving normally, and an interface that shows them a
/// red banner for it is wrong. This case exists precisely so that the caller
/// can tell "nothing happened" from "something broke".
final class CaptureCancelled extends CaptureFailure {
  /// Records that the user dismissed the camera.
  const CaptureCancelled();

  @override
  String toString() => 'CaptureCancelled()';
}

/// The platform failed for a reason none of the other cases describes.
final class CaptureUnavailable extends CaptureFailure {
  /// Records an unclassified failure, with [detail] for the log.
  const CaptureUnavailable({required this.detail});

  /// What the adapter saw. Never rendered to a user.
  final String detail;

  @override
  String toString() => 'CaptureUnavailable($detail)';
}
