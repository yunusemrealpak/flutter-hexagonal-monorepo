import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the identity ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather
/// than in an adapter, because a failure is part of a contract: the package
/// that owns the port owns what failing it means.
sealed class IdentityFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const IdentityFailure();
}

/// Nothing is stored under the identifier that was asked for.
final class IdentityNotFound extends IdentityFailure {
  /// Creates the failure for [id].
  const IdentityNotFound(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'IdentityNotFound($id)';
}

/// The outside world could not be reached, so nothing is known either way.
///
/// Distinct from [IdentityNotFound] on purpose: "absent" and "unknown" call
/// for different behaviour in the caller, and collapsing them is how a retry
/// becomes a deletion.
final class IdentityUnavailable extends IdentityFailure {
  /// Creates the failure.
  const IdentityUnavailable();

  @override
  String toString() => 'IdentityUnavailable()';
}
