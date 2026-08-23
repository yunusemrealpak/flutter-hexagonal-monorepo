import 'package:core_kernel/core_kernel.dart';

/// Carries domain events between packages that do not know each other.
///
/// This is the mechanism behind scenario 2 of the architecture:
/// `delivery_application` publishes `DeliveryCompleted` and
/// `payments_application` reacts by closing the matching collection. Neither
/// package appears in the other's pubspec. Both depend on this port, and the
/// only thing either of them knows about the other is a [DomainEvent] subtype
/// that lives in an `_api` package they both already read.
///
/// The trade is real and worth naming. Events buy decoupling and cost
/// traceability: nothing in `delivery_application` says who reacts to a
/// completed delivery, and finding out means searching for subscribers. Use an
/// event when the publisher genuinely should not care whether anyone is
/// listening; call a port directly when it should.
///
/// Publishing does not fail and does not return a [Future]. A publisher must
/// not be able to observe whether a subscriber succeeded — the moment it can,
/// the coupling the bus was meant to remove is back.
abstract interface class DomainEventBus {
  /// Delivers [event] to every current subscriber whose type matches.
  void publish(DomainEvent event);

  /// The stream of published events of type [T].
  ///
  /// Events published before subscription are not replayed. The bus is a
  /// notification channel, not a log; anything that needs durability belongs
  /// in the `sync` outbox.
  Stream<T> on<T extends DomainEvent>();
}
