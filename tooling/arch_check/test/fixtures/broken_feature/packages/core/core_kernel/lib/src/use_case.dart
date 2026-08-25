/// The shape every use case takes.
abstract interface class UseCase<TInput, TOutput> {
  /// Runs it.
  Future<TOutput> call(TInput input);
}
