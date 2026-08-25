/// The outcome of an operation that can fail.
sealed class Result<S, F> {
  /// Const so a result can be built in a const context.
  const Result();
}

/// A successful outcome.
final class Success<S, F> extends Result<S, F> {
  /// Creates it.
  const Success(this.value);

  /// The value.
  final S value;
}

/// A failed outcome.
final class Failed<S, F> extends Result<S, F> {
  /// Creates it.
  const Failed(this.failure);

  /// The failure.
  final F failure;
}
