@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

ActorId _id(String raw) => switch (ActorId.parse(raw)) {
  Success(:final value) => value,
  Failed(:final failure) => throw StateError('$failure'),
};

void main() {
  group('ActorId', () {
    test('trims surrounding whitespace', () {
      expect(_id('  ali  ').value, 'ali');
    });

    test('refuses an empty identifier', () {
      expect(
        ActorId.parse('   '),
        const Failed<ActorId, IdentityFailure>(
          MalformedActorId(''),
        ),
      );
    });

    test('does not fold case, because the server does not', () {
      expect(_id('Ali'), isNot(_id('ali')));
    });
  });

  group('Actor identity', () {
    test('the same actor with different contents is still the same actor', () {
      final before = Actor(
        id: _id('ali'),
        displayName: 'Ali',
        roles: {Role.courier},
      );
      final after = before.copyWith(
        displayName: 'Ali Veli',
        roles: {Role.courier, Role.dispatcher},
      );

      // This is the assertion the whole hand-written-entity decision exists
      // for. Generated structural equality would make these two unequal, and
      // "has this actor changed?" would stop being a question anyone could
      // ask separately from "is this the same actor?".
      expect(after, before);
      expect(after.hashCode, before.hashCode);
      expect(after.displayName, isNot(before.displayName));
    });

    test('two different actors are not equal', () {
      final ali = Actor(id: _id('ali'), displayName: 'Ali', roles: const {});
      final veli = Actor(id: _id('veli'), displayName: 'Ali', roles: const {});

      expect(ali, isNot(veli));
    });

    test('roles cannot be mutated through the entity', () {
      final roles = {Role.courier};
      final actor = Actor(id: _id('ali'), displayName: 'Ali', roles: roles);

      expect(() => actor.roles.add(Role.supervisor), throwsUnsupportedError);

      roles.add(Role.supervisor);
      expect(actor.roles, hasLength(1), reason: 'the set was copied, not held');
    });
  });

  group('Actor.can', () {
    test('grants what the roles grant', () {
      final courier = Actor(
        id: _id('ali'),
        displayName: 'Ali',
        roles: {Role.courier},
      );

      expect(courier.can(Permission.completeDelivery), isTrue);
      expect(courier.can(Permission.refundPayment), isFalse);
    });

    test('two roles grant the union of both', () {
      final both = Actor(
        id: _id('ali'),
        displayName: 'Ali',
        roles: {Role.courier, Role.dispatcher},
      );

      expect(both.can(Permission.completeDelivery), isTrue);
      expect(both.can(Permission.bulkAssignShipments), isTrue);
    });

    test('a direct grant adds to the roles without changing them', () {
      final courier = Actor(
        id: _id('ali'),
        displayName: 'Ali',
        roles: {Role.courier},
        directGrants: PermissionSet.of(const [Permission.refundPayment]),
      );

      expect(courier.can(Permission.refundPayment), isTrue);
      expect(courier.can(Permission.completeDelivery), isTrue);
      expect(
        Role.courier.permissions.contains(Permission.refundPayment),
        isFalse,
        reason: 'the grant is personal; the role is untouched',
      );
    });

    test('an actor with no role at all may do nothing', () {
      final nobody = Actor(
        id: _id('ali'),
        displayName: 'Ali',
        roles: const {},
      );

      for (final permission in Permission.values) {
        expect(nobody.can(permission), isFalse);
      }
    });
  });
}
