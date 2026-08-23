/// The base type of everything that can be returned as the failure side of a
/// `Result` in product code.
///
/// Deliberately empty. A failure's useful content — which cases exist, what
/// each one carries, what the caller is expected to do about it — belongs to
/// the package that declares the port, as a `sealed class` extending this one:
///
/// ```dart
/// sealed class ShipmentFailure extends Failure {
///   const ShipmentFailure();
/// }
///
/// final class InvalidTransition extends ShipmentFailure { ... }
/// final class ShipmentNotFound extends ShipmentFailure { ... }
/// ```
///
/// Two things were considered for this class and left out. A `message` getter
/// was rejected because it invites callers to render a failure instead of
/// handling it, and because the sealed subtypes already print usefully through
/// `toString`. A stable `code` string was rejected because every failure would
/// then have to invent one whether or not anything consumes it; a feature that
/// needs codes for analytics can declare them on its own hierarchy.
///
/// The class is not `base` or `interface`, so that `freezed` can generate
/// sealed failure unions that extend it without fighting class modifiers.
abstract class Failure {
  /// Const so that failure instances can be built in const contexts.
  const Failure();
}
