/// The outcome of an operation that can fail.
sealed class Result<S, F> {
  const Result();
}

/// A successful outcome.
final class Success<S, F> extends Result<S, F> {
  const Success(this.value);

  final S value;
}

/// A failed outcome.
final class Failed<S, F> extends Result<S, F> {
  const Failed(this.failure);

  final F failure;
}
