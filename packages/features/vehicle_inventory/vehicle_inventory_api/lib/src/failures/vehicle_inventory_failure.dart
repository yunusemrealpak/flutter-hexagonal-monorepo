import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the vehicle inventory ports.
sealed class VehicleInventoryFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const VehicleInventoryFailure();
}

/// The manifest could not be obtained.
///
/// Its own case rather than a general failure because it is the one that
/// happens in a depot basement with no signal, and the answer to it is a
/// cached manifest rather than an error on a courier's screen.
final class ManifestUnavailable extends VehicleInventoryFailure {
  /// Records that the manifest could not be read, with [detail] for the log.
  const ManifestUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'ManifestUnavailable(${detail ?? 'no detail'})';
}

/// The count could not be read or written.
final class CountUnavailable extends VehicleInventoryFailure {
  /// Records that the store did not answer, with [detail] for the log.
  const CountUnavailable({this.detail});

  /// Adapter-supplied context. Never rendered to a user.
  final String? detail;

  @override
  String toString() => 'CountUnavailable(${detail ?? 'no detail'})';
}

/// There is no count under the identifier that was asked for.
final class CountMissing extends VehicleInventoryFailure {
  /// Records that [id] is not stored.
  const CountMissing(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'CountMissing($id)';
}

/// The count is closed, and what was asked for only makes sense while it is
/// open.
final class CountClosed extends VehicleInventoryFailure {
  /// Records that [attempted] was asked of a closed count.
  const CountClosed(this.attempted);

  /// What was asked for.
  final String attempted;

  @override
  String toString() => 'CountClosed($attempted)';
}

/// A value the count carries was refused at construction.
final class MalformedCount extends VehicleInventoryFailure {
  /// Records that [field] was given a value described by [reason].
  const MalformedCount({required this.field, required this.reason});

  /// Which part refused its value.
  final String field;

  /// Why it was refused.
  final String reason;

  @override
  String toString() => 'MalformedCount($field: $reason)';
}
