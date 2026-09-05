/// One durable write a feature wants carried to the server, expressed in
/// terms `sync` can understand without knowing what it is.
///
/// This interface is the whole of scenario 3. Every feature that writes
/// offline implements it — `delivery` with a completed attempt, `payments`
/// with a collection, `incidents` with a report — and `sync` never learns any
/// of their names. The arrow runs the other way to the intuition: features
/// depend on `sync_api`, and `sync` depends on no feature at all.
///
/// The interface is deliberately two strings and nothing more.
///
/// [type] is what the composition root matches on when it decides which
/// transport handler carries this command. It is a routing key, and it belongs
/// to the feature that declared it — `delivery.completeAttempt` rather than
/// `command_3`, so that an entry sitting in a stuck outbox can be read by a
/// person.
///
/// [payload] is already serialised. `sync` stores it, hands it to a transport
/// and never decodes it, which is what lets an outbox row be a `TEXT` column
/// and what stops `sync_application` growing a JSON codec — or, worse, a
/// switch over feature names. The feature that wrote the payload is the only
/// thing that reads it back.
///
/// Implementations live in the feature's own `_application` package, beside
/// the use case that builds and enqueues one. They are values, not adapters:
/// nothing about them touches the outside world.
abstract interface class SyncCommand {
  /// The routing key the composition root maps to a transport handler.
  ///
  /// Stable across releases. Changing it strands every entry already queued
  /// on a device that has not drained, because the registry in the app will
  /// no longer have a handler for the old string.
  String get type;

  /// The command's body, already serialised by the feature that made it.
  String get payload;
}
