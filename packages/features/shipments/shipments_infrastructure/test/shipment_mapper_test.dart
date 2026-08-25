@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:shipments_testing/shipments_testing.dart';
import 'package:test/test.dart';

Map<String, dynamic> _wire({
  Object? id = 'ship-1',
  Object? barcode = '100000000007',
  Map<String, dynamic>? status,
  Object? consignee = _absent,
}) => <String, dynamic>{
  if (id != _absent) 'id': id,
  if (barcode != _absent) 'barcode': barcode,
  'status': status ?? <String, dynamic>{'kind': 'awaitingAssignment'},
  if (consignee != _absent)
    'consignee': consignee
  else
    'consignee': <String, dynamic>{
      'name': 'Ayse Yilmaz',
      'phone': '+90 555 000 0000',
      'address': <String, dynamic>{
        'formatted': 'Bagdat Cd. 100',
        'latitude': 40.96,
        'longitude': 29.06,
      },
    },
};

const Object _absent = Object();

ShipmentFailure? _failureOf(Result<Object?, ShipmentFailure> result) =>
    result.fold((_) => null, (failure) => failure);

void main() {
  // Inferred, not annotated: writing `ActorId` here would need an import of
  // identity_api, which section 2 forbids this package outright. The type is
  // still exact — CourierReference in shipments_api is what produces it.
  final courier = CourierReference.parse(
    'courier-1',
  ).fold((id) => id, (f) => throw StateError('$f'));

  group('what arrives is checked, not trusted', () {
    test('a complete message maps to a shipment', () {
      final result = ShipmentMapper.toDomain(ShipmentDto.fromJson(_wire()));

      final shipment = result.fold((s) => s, (f) => throw StateError('$f'));
      expect(shipment.id.value, 'ship-1');
      expect(shipment.barcode.value, '100000000007');
      expect(shipment.status, const ShipmentStatus.awaitingAssignment());
      expect(shipment.consignee.name, 'Ayse Yilmaz');
    });

    test('an absent field is a named failure, not a TypeError', () {
      // The reason the mapper is hand-written. A generator turns JSON into a
      // data class; it does not decide that a missing barcode is worth saying
      // out loud.
      expect(
        _failureOf(
          ShipmentMapper.toDomain(ShipmentDto.fromJson(_wire(barcode: null))),
        ),
        const MalformedValue(field: 'barcode', reason: 'is absent'),
      );
    });

    test('a barcode that fails its check digit is refused at the boundary', () {
      expect(
        _failureOf(
          ShipmentMapper.toDomain(
            ShipmentDto.fromJson(_wire(barcode: '100000000008')),
          ),
        ),
        isA<MalformedBarcode>(),
      );
    });

    test('an unknown state is refused rather than guessed at', () {
      // Falling back to "awaiting assignment" would put a parcel the operation
      // has already delivered back at the top of somebody's manifest.
      expect(
        _failureOf(
          ShipmentMapper.toDomain(
            ShipmentDto.fromJson(
              _wire(status: {'kind': 'teleported'}),
            ),
          ),
        ),
        const MalformedValue(
          field: 'status.kind',
          reason: 'unknown state teleported',
        ),
      );
    });

    test('a delivered state without a proof reference is refused', () {
      expect(
        _failureOf(
          ShipmentMapper.toDomain(
            ShipmentDto.fromJson(
              _wire(
                status: {
                  'kind': 'deliveredToConsignee',
                  'at': '2026-03-14T12:00:00Z',
                },
              ),
            ),
          ),
        ),
        const MalformedValue(
          field: 'status.proofReference',
          reason: 'is absent on a delivered shipment',
        ),
      );
    });

    test('a state that needs a courier and has none is refused', () {
      expect(
        _failureOf(
          ShipmentMapper.toDomain(
            ShipmentDto.fromJson(
              _wire(status: {'kind': 'outForDelivery'}),
            ),
          ),
        ),
        const MalformedValue(
          field: 'status.courier',
          reason: 'is absent on a state that has one',
        ),
      );
    });

    test('a timestamp that is not ISO-8601 is refused', () {
      expect(
        _failureOf(
          ShipmentMapper.toDomain(
            ShipmentDto.fromJson(
              _wire(
                status: {'kind': 'returnedToDepot', 'at': 'yesterday'},
              ),
            ),
          ),
        ),
        const MalformedValue(
          field: 'status.at',
          reason: 'is not an ISO-8601 instant',
        ),
      );
    });

    test('a local timestamp is normalised to UTC', () {
      // Clock promises UTC. A local DateTime compared against one is off by
      // whatever the device's offset happens to be — a bug that only shows up
      // for users in the wrong timezone.
      final result = ShipmentMapper.toDomain(
        ShipmentDto.fromJson(
          _wire(
            status: {
              'kind': 'returnedToDepot',
              'at': '2026-03-14T15:00:00+03:00',
            },
          ),
        ),
      );

      final status =
          result.fold((s) => s.status, (f) => throw StateError('$f'))
              as ShipmentReturnedToDepot;
      expect(status.at.isUtc, isTrue);
      expect(status.at, DateTime.utc(2026, 3, 14, 12));
    });
  });

  group('a round trip loses nothing', () {
    test('domain to wire and back is the same shipment', () {
      final original = ShipmentBuilder()
          .withId('ship-1')
          .assignedTo(courier)
          .loaded()
          .outForDelivery()
          .delivered(proofReference: 'proof-9')
          .build();

      final round = ShipmentMapper.toDomain(
        ShipmentDto.fromJson(ShipmentMapper.toDto(original).toJson()),
      ).fold((s) => s, (f) => throw StateError('$f'));

      expect(round.id, original.id);
      expect(round.barcode, original.barcode);
      expect(round.status, original.status);
      expect(round.consignee, original.consignee);
      expect(round.history, original.history);
    });

    test('a system-made move keeps its absent actor', () {
      final original = ShipmentBuilder()
          .withId('ship-1')
          .assignedTo(courier)
          .loaded()
          .outForDelivery()
          .returnedToDepot()
          .build();

      final round = ShipmentMapper.toDomain(
        ShipmentDto.fromJson(ShipmentMapper.toDto(original).toJson()),
      ).fold((s) => s, (f) => throw StateError('$f'));

      expect(round.history.last.by, isNull);
      expect(round.history.first.by, courier);
    });
  });
}
