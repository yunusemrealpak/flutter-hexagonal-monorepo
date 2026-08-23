@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

final class _DeliveryCompleted extends DomainEvent {
  const _DeliveryCompleted({
    required super.occurredAt,
    required this.shipmentId,
  });

  final String shipmentId;
}

void main() {
  test('carries the timestamp it was given rather than reading a clock', () {
    // A fixed instant standing in for what a Clock port would return. Nothing
    // in this test can drift, because nothing in it asks the system for time.
    final instant = DateTime.utc(2026, 3, 14, 15, 9, 26);

    final event = _DeliveryCompleted(
      occurredAt: instant,
      shipmentId: 's-1',
    );

    expect(event.occurredAt, instant);
  });

  test('carries its own payload alongside the base timestamp', () {
    final event = _DeliveryCompleted(
      occurredAt: DateTime.utc(2026),
      shipmentId: 's-42',
    );

    expect(event.shipmentId, 's-42');
    expect(event, isA<DomainEvent>());
  });
}
