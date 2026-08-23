@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

final class _ShipmentId extends ValueObject<String> {
  const _ShipmentId(super.value);
}

/// An entity whose contents change while its identity does not — the exact
/// case identity-based equality exists for.
final class _Shipment extends Entity<_ShipmentId> {
  const _Shipment({required super.id, required this.status});

  final String status;

  _Shipment copyWith({String? status}) =>
      _Shipment(id: id, status: status ?? this.status);
}

final class _Consignee extends Entity<_ShipmentId> {
  const _Consignee({required super.id});
}

void main() {
  group('identity', () {
    test('an entity stays equal to itself after its contents change', () {
      const before = _Shipment(id: _ShipmentId('s-1'), status: 'assigned');
      final after = before.copyWith(status: 'loaded');

      expect(after, before);
      expect(after.status, isNot(before.status));
    });

    test('entities with different identifiers are not equal', () {
      const first = _Shipment(id: _ShipmentId('s-1'), status: 'assigned');
      const second = _Shipment(id: _ShipmentId('s-2'), status: 'assigned');

      expect(first, isNot(second));
    });

    test('different entity types sharing an identifier are not equal', () {
      const shipment = _Shipment(id: _ShipmentId('s-1'), status: 'assigned');
      const consignee = _Consignee(id: _ShipmentId('s-1'));

      expect(shipment, isNot(consignee));
    });

    test('hashes by identity, so a Set deduplicates by identifier', () {
      final shipments = <_Shipment>{
        const _Shipment(id: _ShipmentId('s-1'), status: 'assigned'),
        const _Shipment(id: _ShipmentId('s-1'), status: 'delivered'),
      };

      expect(shipments, hasLength(1));
    });
  });

  test('prints as type and identifier', () {
    const shipment = _Shipment(id: _ShipmentId('s-1'), status: 'assigned');

    expect(shipment.toString(), '_Shipment(_ShipmentId(s-1))');
  });
}
