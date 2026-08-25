@Tags(['unit'])
library;

import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:test/test.dart';

Map<String, dynamic> _sessionJson({
  String actorId = 'courier-1',
  List<String> roles = const ['courier'],
  String token = 'jwt.abc',
}) => <String, dynamic>{
  'actor': {
    'id': actorId,
    'displayName': 'Ali Veli',
    'roles': roles,
    'grants': <String>[],
  },
  'accessToken': token,
  'expiresAt': '2026-03-14T13:00:00Z',
  'refreshableUntil': '2026-03-21T12:00:00Z',
  'device': {
    'deviceId': 'handset-1',
    'fingerprint': 'sha256:aaa',
    'boundAt': '2026-02-12T12:00:00Z',
  },
};

void main() {
  group('SecureSessionStore', () {
    // The contract kit, against the adapter that actually ships. The same
    // suite runs in identity_testing against the in-memory store.
    runSessionStoreContract(
      () => SecureSessionStore(store: InMemorySecureStore()),
    );

    test('an invalidated key reads as signed out, not as a failure', () async {
      // What a keychain says after a passcode change or a restore from backup.
      // Reporting it as a failure would leave the app on an error screen it
      // can never clear — the user would have to reinstall to sign in again.
      final secure = InMemorySecureStore()
        ..failNextWith(const SecureStoreKeyInvalidated());
      final store = SecureSessionStore(store: secure);

      expect(
        await store.read(),
        const Success<Session?, IdentityFailure>(null),
      );
    });

    test('an unreadable entry reads as signed out too', () async {
      final secure = InMemorySecureStore();
      await secure.write(SecureSessionStore.key, 'not json at all');

      expect(
        await SecureSessionStore(store: secure).read(),
        const Success<Session?, IdentityFailure>(null),
      );
    });

    test('a store that is simply unavailable is still a failure', () async {
      // Unlike the two above: this one is worth retrying, and turning it into
      // "signed out" would sign a courier out because the phone was locked.
      final secure = InMemorySecureStore()
        ..failNextWith(const SecureStoreUnavailable());

      expect(
        (await SecureSessionStore(store: secure).read()).isFailure,
        isTrue,
      );
    });
  });

  group('InstallationDeviceRegistry', () {
    late InMemoryKeyValueStore store;
    late InstallationDeviceRegistry registry;

    setUp(() {
      store = InMemoryKeyValueStore();
      registry = InstallationDeviceRegistry(
        store: store,
        ids: FakeIdGenerator('device'),
        clock: FakeClock(SessionBuilder.now),
        fingerprint: 'sha256:aaa',
      );
    });

    test('mints an identifier once and reuses it', () async {
      // A restart must not look like a new device. The identifier comes from
      // the IdGenerator port, so this assertion is exact rather than a
      // wildcard match on a uuid.
      final first = await registry.currentBinding();
      final second = await registry.currentBinding();

      expect(
        first.fold((b) => b.deviceId, (f) => throw StateError('$f')),
        second.fold((b) => b.deviceId, (f) => throw StateError('$f')),
      );
    });

    test('stamps the binding from the Clock port', () async {
      final binding = await registry.currentBinding();

      expect(
        binding.fold((b) => b.boundAt, (f) => throw StateError('$f')),
        SessionBuilder.now,
      );
    });

    test(
      'reports a store it cannot read rather than minting a new device',
      () async {
        store.failNextWith(const StoreUnavailable(detail: 'locked'));

        expect((await registry.currentBinding()).isFailure, isTrue);
      },
    );
  });

  group('the two credential gateways', () {
    test(
      'the device-bound one refuses an SSO assertion without asking',
      () async {
        // Refused here rather than sent and rejected. An adapter that forwarded
        // credentials it cannot serve would turn a configuration mistake into a
        // network round trip and a message nobody can act on.
        final transport = FakeHttpTransport();
        final gateway = DeviceBoundCredentialGateway(transport: transport);

        final result = await gateway.authenticate(
          credentials: SsoAssertionCredentials.create(
            '<saml/>',
          ).fold((c) => c, (f) => throw StateError('$f')),
          binding: SessionBuilder().buildBinding(),
        );

        expect(
          result,
          const Failed<Session, IdentityFailure>(InvalidCredentials()),
        );
        expect(transport.requests, isEmpty, reason: 'nothing was sent');
      },
    );

    test('the SSO one refuses a password without asking', () async {
      final transport = FakeHttpTransport();
      final gateway = SsoCredentialGateway(
        transport: transport,
        realm: 'peyk-ops',
      );

      final result = await gateway.authenticate(
        credentials: PasswordCredentials.create(
          actorId: 'dispatcher-1',
          secret: 'hunter2',
        ).fold((c) => c, (f) => throw StateError('$f')),
        binding: SessionBuilder().buildBinding(),
      );

      expect(
        result,
        const Failed<Session, IdentityFailure>(InvalidCredentials()),
      );
      expect(transport.requests, isEmpty);
    });

    test('both produce the same Session from the same body', () async {
      // Scenario 5: one port, two adapters, and nothing above them can tell
      // which one answered.
      final deviceTransport = FakeHttpTransport()
        ..enqueueJson(jsonEncode(_sessionJson()));
      final ssoTransport = FakeHttpTransport()
        ..enqueueJson(jsonEncode(_sessionJson()));

      final fromDevice =
          await DeviceBoundCredentialGateway(
            transport: deviceTransport,
          ).authenticate(
            credentials: PasswordCredentials.create(
              actorId: 'courier-1',
              secret: 'hunter2',
            ).fold((c) => c, (f) => throw StateError('$f')),
            binding: SessionBuilder().buildBinding(),
          );

      final fromSso =
          await SsoCredentialGateway(
            transport: ssoTransport,
            realm: 'peyk-ops',
          ).authenticate(
            credentials: SsoAssertionCredentials.create(
              '<saml/>',
            ).fold((c) => c, (f) => throw StateError('$f')),
            binding: SessionBuilder().buildBinding(),
          );

      expect(fromDevice, fromSso);
      expect(fromDevice.isSuccess, isTrue);
    });

    test('a 401 is InvalidCredentials, not a transport failure', () async {
      // The caller handles IdentityFailure and must never see a status code:
      // a use case that switched on one would stop compiling the day the API
      // moves to gRPC.
      final transport = FakeHttpTransport()
        ..enqueueFailure(
          const TransportRejected(HttpResponse(statusCode: 401)),
        );

      final result = await DeviceBoundCredentialGateway(transport: transport)
          .authenticate(
            credentials: PasswordCredentials.create(
              actorId: 'courier-1',
              secret: 'wrong',
            ).fold((c) => c, (f) => throw StateError('$f')),
            binding: SessionBuilder().buildBinding(),
          );

      expect(
        result,
        const Failed<Session, IdentityFailure>(InvalidCredentials()),
      );
    });

    test('the password never reaches a log line', () async {
      final transport = FakeHttpTransport()
        ..enqueueJson(jsonEncode(_sessionJson()));
      final credentials = PasswordCredentials.create(
        actorId: 'courier-1',
        secret: 'hunter2',
      ).fold((c) => c, (f) => throw StateError('$f'));

      await DeviceBoundCredentialGateway(transport: transport).authenticate(
        credentials: credentials,
        binding: SessionBuilder().buildBinding(),
      );

      // The body carries it, because the server needs it. Everything a human
      // reads does not.
      expect('$credentials', isNot(contains('hunter2')));
      expect('${transport.lastRequest}', isNot(contains('hunter2')));
    });
  });

  group('SessionMapper', () {
    test('drops a role this build does not know, rather than refusing', () {
      // The opposite of ShipmentMapper's unknown-state rule, and the direction
      // is the point: an unknown role can only grant permissions this build
      // also does not understand, so dropping it removes access rather than
      // inventing it. Refusing would lock every courier out of an older app
      // the day a new role appears on the server.
      final result = SessionMapper.toDomain(
        SessionDto.fromJson(
          _sessionJson(roles: ['courier', 'chief_wizard']),
        ),
      );

      final session = result.fold((s) => s, (f) => throw StateError('$f'));
      expect(session.actor.roles, {Role.courier});
    });

    test('a round trip loses nothing that decides a rule', () {
      final original = SessionBuilder()
          .withRoles({Role.dispatcher})
          .granting(Permission.refundPayment)
          .tokenLife(const Duration(minutes: 42))
          .build();

      final round = SessionMapper.toDomain(
        SessionDto.fromJson(SessionMapper.toDto(original).toJson()),
      ).fold((s) => s, (f) => throw StateError('$f'));

      expect(round, original);
      expect(round.actor.can(Permission.refundPayment), isTrue);
    });

    test('a local expiry is normalised to UTC', () {
      final json = _sessionJson()..['expiresAt'] = '2026-03-14T16:00:00+03:00';

      final session = SessionMapper.toDomain(
        SessionDto.fromJson(json),
      ).fold((s) => s, (f) => throw StateError('$f'));

      expect(session.accessToken.expiresAt, DateTime.utc(2026, 3, 14, 13));
    });
  });
}
