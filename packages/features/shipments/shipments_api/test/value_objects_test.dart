@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('ShipmentId', () {
    test('trims and accepts', () {
      expect(unwrap(ShipmentId.parse('  ship-1 ')).value, 'ship-1');
    });

    test('refuses an empty identifier and echoes what it was given', () {
      expect(
        ShipmentId.parse('   '),
        const Failed<ShipmentId, ShipmentFailure>(MalformedShipmentId('   ')),
      );
    });
  });

  group('AddressPoint', () {
    test('accepts an address with no coordinates', () {
      final address = unwrap(AddressPoint.create(formatted: 'Depo 1'));

      expect(address.isGeocoded, isFalse);
    });

    test('refuses half a coordinate pair', () {
      // Half a pair is not half a location: it would travel as far as a map
      // pin on the equator.
      expect(
        AddressPoint.create(formatted: 'Depo 1', latitude: 41),
        const Failed<AddressPoint, ShipmentFailure>(
          MalformedValue(
            field: 'address',
            reason: 'latitude and longitude are given together or not at all',
          ),
        ),
      );
    });

    test('refuses a latitude outside the globe', () {
      expect(
        AddressPoint.create(
          formatted: 'Depo 1',
          latitude: 91,
          longitude: 29,
        ).isFailure,
        isTrue,
      );
    });

    test('refuses a longitude outside the globe', () {
      expect(
        AddressPoint.create(
          formatted: 'Depo 1',
          latitude: 41,
          longitude: 181,
        ).isFailure,
        isTrue,
      );
    });

    test('accepts the poles and the antimeridian', () {
      expect(
        AddressPoint.create(
          formatted: 'edge',
          latitude: -90,
          longitude: 180,
        ).isSuccess,
        isTrue,
      );
    });

    test('refuses an empty address', () {
      expect(AddressPoint.create(formatted: '  ').isFailure, isTrue);
    });
  });

  group('Consignee', () {
    test('refuses an empty name', () {
      expect(
        Consignee.create(
          name: '  ',
          address: unwrap(AddressPoint.create(formatted: 'Depo 1')),
        ).isFailure,
        isTrue,
      );
    });

    test('accepts an absent phone number', () {
      final person = unwrap(
        Consignee.create(
          name: 'Ayse',
          address: unwrap(AddressPoint.create(formatted: 'Depo 1')),
        ),
      );

      expect(person.phone, isNull);
    });

    test('refuses a phone number that is present but blank', () {
      // "Present but empty" is a different mistake from "absent", and letting
      // it through would put a blank tel: link on a screen.
      expect(
        Consignee.create(
          name: 'Ayse',
          address: unwrap(AddressPoint.create(formatted: 'Depo 1')),
          phone: '   ',
        ).isFailure,
        isTrue,
      );
    });

    test('does not validate the shape of a phone number', () {
      // Peyk delivers across borders. A contract package that decided what a
      // phone number looks like would be wrong in whichever country it was
      // not written in.
      expect(
        Consignee.create(
          name: 'Ayse',
          address: unwrap(AddressPoint.create(formatted: 'Depo 1')),
          phone: '00 90 (555) 000-00-00 ext. 12',
        ).isSuccess,
        isTrue,
      );
    });

    test('two consignees with the same contents are equal', () {
      expect(consignee(), consignee());
      expect(consignee().hashCode, consignee().hashCode);
    });
  });
}
