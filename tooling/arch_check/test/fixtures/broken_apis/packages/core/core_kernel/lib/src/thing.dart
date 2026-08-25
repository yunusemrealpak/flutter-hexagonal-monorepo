/// The outcome of an operation that can fail.
sealed class Result<S, F> {
  const Result();
}

/// A successful outcome.
final class Success<S, F> extends Result<S, F> {
  /// Creates it.
  const Success(this.value);

  /// The value.
  final S value;
}
