@Tags(['unit'])
library;

import 'package:scaffold/scaffold.dart';
import 'package:test/test.dart';

void main() {
  group('spellings', () {
    test('snake_case becomes PascalCase', () {
      expect(Naming('billing').featurePascal, 'Billing');
      expect(Naming('vehicle_inventory').featurePascal, 'VehicleInventory');
    });

    test('a presentation variant is appended to the type name', () {
      final naming = Naming('shipments', variant: 'courier');
      expect(naming.pascal, 'ShipmentsCourier');
      expect(naming.snake, 'shipments_courier');
    });

    test('without a variant the two spellings agree', () {
      final naming = Naming('shipments');
      expect(naming.pascal, 'Shipments');
      expect(naming.snake, 'shipments');
    });
  });

  group('validation', () {
    test('accepts what pub accepts', () {
      for (final name in ['billing', 'vehicle_inventory', 'a1', 'a_1_b']) {
        expect(Naming.isValidFeatureName(name), isTrue, reason: name);
      }
    });

    test('rejects what would produce an unresolvable workspace', () {
      // A name pub rejects is a name that makes `dart pub get` fail on every
      // package in the repository, not only on the one just generated.
      for (final name in [
        '',
        'Billing',
        '1billing',
        'billing-api',
        'billing_',
        '_billing',
        'billing api',
      ]) {
        expect(Naming.isValidFeatureName(name), isFalse, reason: '"$name"');
      }
    });
  });
}
