import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the routing ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather
/// than in an adapter, because a failure is part of a contract: the package
/// that owns the port owns what failing it means.
sealed class RoutingFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const RoutingFailure();
}

/// Nothing is stored under the identifier that was asked for.
final class RoutingNotFound extends RoutingFailure {
  /// Creates the failure for [id].
  const RoutingNotFound(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'RoutingNotFound($id)';
}

/// The outside world could not be reached, so nothing is known either way.
///
/// Distinct from [RoutingNotFound] on purpose: "absent" and "unknown" call
/// for different behaviour in the caller, and collapsing them is how a retry
/// becomes a deletion.
final class RoutingUnavailable extends RoutingFailure {
  /// Creates the failure.
  const RoutingUnavailable();

  @override
  String toString() => 'RoutingUnavailable()';
}
