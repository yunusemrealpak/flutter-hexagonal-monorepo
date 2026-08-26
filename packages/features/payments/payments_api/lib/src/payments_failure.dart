import 'package:core_kernel/core_kernel.dart';

/// Everything that can go wrong on the payments ports.
///
/// Sealed, so a caller that handles the cases exhaustively keeps compiling
/// only for as long as it still handles all of them. Declared here rather
/// than in an adapter, because a failure is part of a contract: the package
/// that owns the port owns what failing it means.
sealed class PaymentsFailure extends Failure {
  /// Const so that a failure can be built in a const context.
  const PaymentsFailure();
}

/// Nothing is stored under the identifier that was asked for.
final class PaymentsNotFound extends PaymentsFailure {
  /// Creates the failure for [id].
  const PaymentsNotFound(this.id);

  /// The identifier that produced nothing.
  final String id;

  @override
  String toString() => 'PaymentsNotFound($id)';
}

/// The outside world could not be reached, so nothing is known either way.
///
/// Distinct from [PaymentsNotFound] on purpose: "absent" and "unknown" call
/// for different behaviour in the caller, and collapsing them is how a retry
/// becomes a deletion.
final class PaymentsUnavailable extends PaymentsFailure {
  /// Creates the failure.
  const PaymentsUnavailable();

  @override
  String toString() => 'PaymentsUnavailable()';
}
