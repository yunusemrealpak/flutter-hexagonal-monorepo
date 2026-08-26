/// The delivery use cases: pure Dart, and blind to every adapter behind them.
///
/// Two things in this package are worth reading for the architecture rather
/// than for the feature.
///
/// **`CompleteDeliveryCommand` is delivery's half of scenario 3.** It
/// implements `SyncCommand` — a routing key and a serialised payload — so that
/// a completed delivery survives a basement. `sync` carries it and never
/// learns what it is; the dependency runs from here to `sync_api` and never
/// the other way. The command lives in this package rather than in `_api` (a
/// serialised payload is a wire concern) or `_infrastructure` (it is a value,
/// and a use case has to be able to build one).
///
/// **`CompleteWithProof` publishes `DeliveryCompleted` and never learns who
/// listens.** That is scenario 2 from the publisher's side.
/// `payments_application` closes the matching cash collection; neither
/// `_application` package appears in the other's pubspec. The event goes out
/// *after* the queue accepted the write, because a subscriber reacting to a
/// delivery that was never durably recorded is reacting to something that did
/// not happen.
///
/// The order inside that use case is the rest of the design: check the policy
/// before paying for a store, compress against a limit the app supplied, keep
/// the handle and let the bytes stop here, queue rather than send. A courier
/// who has just handed over a parcel is not made to wait for a server.
///
/// `DeliveryCoordinator` implements `DeliveryFacade` by delegating to the four
/// use cases. It stays thin on purpose: if it ever grows a decision of its
/// own, that is the signal a use case is missing.
library;

export 'src/attempt_reads.dart';
export 'src/complete_delivery_command.dart';
export 'src/complete_with_proof.dart';
export 'src/delivery_coordinator.dart';
export 'src/fail_delivery_command.dart';
export 'src/fail_with_reason.dart';
export 'src/start_attempt.dart';
