import 'package:core_ports/src/clock.dart';

/// Produces identifiers.
///
/// The reason this is a port rather than a call to `Uuid()` is the same reason
/// [Clock] is: an identifier generated inside a use case is an input that the
/// test cannot see or predict, so any assertion about it has to be weakened to
/// "some string". Injected, the identifier becomes a value the test chooses.
///
/// It matters most where identity is the behaviour under test. `payments`
/// binds an `IdempotencyKey` to a single payment intention so that every retry
/// of that intention carries the same key; proving that requires a generator
/// whose output the test controls.
abstract interface class IdGenerator {
  /// Returns a new identifier.
  ///
  /// Implementations guarantee uniqueness within the process and, for the
  /// adapters that back offline work, across devices — an outbox entry created
  /// on a phone with no network still has to be distinguishable from one
  /// created on another.
  String newId();
}
