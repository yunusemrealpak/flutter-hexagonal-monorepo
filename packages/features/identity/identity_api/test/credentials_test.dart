@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

void main() {
  group('validation', () {
    test('a password credential needs both halves', () {
      expect(
        PasswordCredentials.create(actorId: 'ali', secret: ''),
        const Failed<PasswordCredentials, IdentityFailure>(
          InvalidCredentials(),
        ),
      );
      expect(
        PasswordCredentials.create(actorId: '  ', secret: 'hunter2'),
        const Failed<PasswordCredentials, IdentityFailure>(
          MalformedActorId(''),
        ),
      );
    });

    test('an SSO assertion needs to be present', () {
      expect(
        SsoAssertionCredentials.create(''),
        const Failed<SsoAssertionCredentials, IdentityFailure>(
          InvalidCredentials(),
        ),
      );
    });

    test('an SSO assertion names no actor of its own', () {
      final credentials = SsoAssertionCredentials.create('<saml/>');

      expect(
        credentials.fold((c) => c.actorId, (f) => throw StateError('$f')),
        isNull,
      );
    });
  });

  group('redaction', () {
    test('no case prints its secret', () {
      final built = <Credentials>[
        PasswordCredentials.create(
          actorId: 'ali',
          secret: 'hunter2',
        ).fold((c) => c, (f) => throw StateError('$f')),
        DeviceTokenCredentials.create(
          actorId: 'ali',
          token: 'device-token',
        ).fold((c) => c, (f) => throw StateError('$f')),
        SsoAssertionCredentials.create(
          'saml-assertion',
        ).fold((c) => c, (f) => throw StateError('$f')),
      ];

      // The reason this hierarchy is hand-written rather than generated: a
      // freezed toString prints every field, and the first log line that
      // interpolated a credential would put a live secret wherever logs go.
      for (final credentials in built) {
        final printed = credentials.toString();
        expect(printed, contains('<redacted>'));
        expect(printed, isNot(contains('hunter2')));
        expect(printed, isNot(contains('device-token')));
        expect(printed, isNot(contains('saml-assertion')));
      }
    });
  });

  group('exhaustiveness', () {
    test('every case is reachable from a switch on the sealed type', () {
      String describe(Credentials credentials) => switch (credentials) {
        PasswordCredentials() => 'password',
        DeviceTokenCredentials() => 'device',
        SsoAssertionCredentials() => 'sso',
      };

      final password = PasswordCredentials.create(
        actorId: 'ali',
        secret: 'hunter2',
      ).fold((c) => c, (f) => throw StateError('$f'));

      expect(describe(password), 'password');
    });
  });
}
