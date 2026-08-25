@Tags(['unit'])
library;

import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

void main() {
  group('PermissionSet', () {
    test('two sets holding the same permissions are equal', () {
      final a = PermissionSet.of(const [
        Permission.viewAllShipments,
        Permission.assignShipment,
      ]);
      final b = PermissionSet.of(const [
        Permission.assignShipment,
        Permission.viewAllShipments,
      ]);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('order does not change the hash', () {
      // This is the assertion that would fail if PermissionSet had extended
      // ValueObject<Set<Permission>> and inherited its identity-based
      // comparison — the reason it does not is documented on the class.
      final forwards = PermissionSet.of(Permission.values);
      final backwards = PermissionSet.of(Permission.values.reversed);

      expect(forwards.hashCode, backwards.hashCode);
    });

    test('a duplicated permission is still one permission', () {
      final set = PermissionSet.of(const [
        Permission.collectPayment,
        Permission.collectPayment,
      ]);

      expect(set.values, hasLength(1));
      expect(set, PermissionSet.of(const [Permission.collectPayment]));
    });

    test('different permissions are not equal', () {
      expect(
        PermissionSet.of(const [Permission.collectPayment]),
        isNot(PermissionSet.of(const [Permission.refundPayment])),
      );
    });

    test('a subset is not equal to its superset', () {
      final small = PermissionSet.of(const [Permission.viewReports]);
      final large = PermissionSet.of(const [
        Permission.viewReports,
        Permission.manageSettings,
      ]);

      expect(small, isNot(large));
      expect(large, isNot(small));
    });

    test('none grants nothing', () {
      for (final permission in Permission.values) {
        expect(PermissionSet.none.contains(permission), isFalse);
      }
    });

    test('union grants what either side grants', () {
      final union = PermissionSet.of(const [
        Permission.viewReports,
      ]).union(PermissionSet.of(const [Permission.collectPayment]));

      expect(union.contains(Permission.viewReports), isTrue);
      expect(union.contains(Permission.collectPayment), isTrue);
      expect(union.contains(Permission.refundPayment), isFalse);
    });

    test('the exposed set cannot be written to', () {
      final set = PermissionSet.of(const [Permission.viewReports]);

      expect(
        () => set.values.add(Permission.manageSettings),
        throwsUnsupportedError,
      );
    });
  });

  group('Role', () {
    test('a courier may deliver and collect, and may not assign', () {
      final courier = Role.courier.permissions;

      expect(courier.contains(Permission.completeDelivery), isTrue);
      expect(courier.contains(Permission.collectPayment), isTrue);
      expect(courier.contains(Permission.bulkAssignShipments), isFalse);
      expect(courier.contains(Permission.viewAllShipments), isFalse);
    });

    test('a dispatcher may assign in bulk and may not take money', () {
      final dispatcher = Role.dispatcher.permissions;

      expect(dispatcher.contains(Permission.bulkAssignShipments), isTrue);
      expect(dispatcher.contains(Permission.collectPayment), isFalse);
    });

    test('an auditor changes nothing', () {
      const writes = [
        Permission.assignShipment,
        Permission.bulkAssignShipments,
        Permission.completeDelivery,
        Permission.collectPayment,
        Permission.refundPayment,
        Permission.manageSettings,
      ];

      for (final permission in writes) {
        expect(
          Role.auditor.permissions.contains(permission),
          isFalse,
          reason: 'auditor should not hold $permission',
        );
      }
    });
  });
}
