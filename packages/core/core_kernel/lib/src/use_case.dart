/// The shape every use case in the workspace takes.
///
/// A use case is one intention the product supports — sign in, complete a
/// delivery, collect a payment — expressed as a single callable object whose
/// collaborators all arrive through its constructor. That constructor is the
/// whole dependency story of the class: there is no service locator inside a
/// package and no global to reach for, so reading the constructor tells you
/// exactly what the use case can touch.
///
/// ```dart
/// final class CompleteDelivery
///     implements UseCase<CompleteDeliveryCommand,
///         Result<DeliveryAttempt, DeliveryFailure>> {
///   const CompleteDelivery({
///     required DeliveryGateway gateway,
///     required Clock clock,
///   })  : _gateway = gateway,
///         _clock = clock;
///
///   final DeliveryGateway _gateway;
///   final Clock _clock;
///
///   @override
///   Future<Result<DeliveryAttempt, DeliveryFailure>> call(
///     CompleteDeliveryCommand command,
///   ) async { ... }
/// }
/// ```
///
/// `TOutput` is left open rather than fixed to `Result` so that the type
/// carries what the use case actually promises. Almost all of them return a
/// `Result`; a query that genuinely cannot fail should not be made to look as
/// if it can.
///
/// A use case that takes no input uses the empty record `()` as `TInput` and
/// is invoked as `useCase(())`. That avoids adding a `NoInput` type to
/// core_kernel for the sake of ergonomics — the language already has one.
abstract interface class UseCase<TInput, TOutput> {
  /// Runs the use case.
  ///
  /// Named `call` so that a use case can be passed and invoked as a function,
  /// which is what makes it substitutable in tests without a wrapper.
  Future<TOutput> call(TInput input);
}
