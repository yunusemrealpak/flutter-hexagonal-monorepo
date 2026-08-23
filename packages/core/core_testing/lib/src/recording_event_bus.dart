import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';

/// A [DomainEventBus] that really delivers and also keeps what it delivered.
///
/// Both halves matter. Delivering for real is what lets a test wire two
/// application packages together and assert on the reaction — that a
/// `DeliveryCompleted` actually closes the matching collection. Recording is
/// what lets the publishing side be tested on its own, without a subscriber.
final class RecordingEventBus implements DomainEventBus {
  final StreamController<DomainEvent> _controller =
      StreamController<DomainEvent>.broadcast();
  final List<DomainEvent> _published = [];

  /// Every event published so far, oldest first.
  List<DomainEvent> get published => List.unmodifiable(_published);

  /// Every published event of type [T].
  List<T> publishedOf<T extends DomainEvent>() =>
      _published.whereType<T>().toList();

  @override
  void publish(DomainEvent event) {
    _published.add(event);
    _controller.add(event);
  }

  @override
  Stream<T> on<T extends DomainEvent>() =>
      // Stream has no whereType; filtering then casting is the same thing
      // without pulling stream_transform into the dependency graph of every
      // package that consumes a fake.
      _controller.stream.where((event) => event is T).cast<T>();

  /// Releases the stream. Call from `addTearDown`.
  Future<void> dispose() => _controller.close();
}
