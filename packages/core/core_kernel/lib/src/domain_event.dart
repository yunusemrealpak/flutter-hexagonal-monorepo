/// The base type of everything published on the domain event bus.
///
/// Domain events are how two features stay decoupled while still reacting to
/// each other. `delivery_application` publishes `DeliveryCompleted`;
/// `payments_application` subscribes and closes the matching collection.
/// Neither package depends on the other — both know only the `DomainEventBus`
/// port in `core_ports`, and the bus itself knows only this type.
///
/// [occurredAt] is required and has no default. That is deliberate: a default
/// would have to come from `DateTime.now()`, and an ambient clock inside the
/// innermost ring would make every event-carrying test non-deterministic. By
/// forcing the timestamp to be passed in, the only way to build an event is to
/// have asked a `Clock` for the time first.
abstract class DomainEvent {
  /// Records when the thing this event describes happened.
  const DomainEvent({required this.occurredAt});

  /// When the event occurred, as reported by the `Clock` port.
  ///
  /// This is domain time — when the delivery completed — not the time the
  /// event was published or delivered to a subscriber.
  final DateTime occurredAt;
}
