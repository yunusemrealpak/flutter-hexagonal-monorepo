@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_application/identity_application.dart';
import 'package:identity_testing/identity_testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeCredentialGateway gateway;
  late InMemorySessionStore store;
  late FakeDeviceRegistry devices;
  late FakeClock clock;
  late RecordingLogger logger;
  late IdentityCoordinator identity;

  final credentials = PasswordCredentials.create(
    actorId: 'courier-1',
    secret: 'hunter2',
  ).fold((c) => c, (f) => throw StateError('$f'));

  setUp(() {
    gateway = FakeCredentialGateway();
    store = InMemorySessionStore();
    devices = FakeDeviceRegistry();
    clock = FakeClock(SessionBuilder.now);
    logger = RecordingLogger();
    identity = IdentityCoordinator(
      gateway: gateway,
      store: store,
      devices: devices,
      clock: clock,
      logger: logger,
    );
    addTearDown(identity.dispose);
  });

  group('signing in', () {
    test('issues a session, stores it and adopts it', () async {
      gateway.accept(credentials);

      final result = await identity.signIn(credentials);

      expect(result.isSuccess, isTrue);
      expect(identity.current, isNotNull);
      expect(store.current, identity.current);
    });

    test('binds the session to the device this app is running on', () async {
      // The binding comes from the use case, not from the adapter. A gateway
      // that issued one for a different device would be issuing a session this
      // app can never validate.
      gateway.accept(credentials);
      devices.binding = SessionBuilder()
          .onDevice('handset-7', fingerprint: 'sha256:ggg')
          .buildBinding();

      final session = await identity.signIn(credentials);

      expect(
        session.fold((s) => s.deviceBinding.deviceId, (f) => 'none'),
        'handset-7',
      );
    });

    test('wrong credentials say nothing about the account', () async {
      expect(
        await identity.signIn(credentials),
        const Failed<Session, IdentityFailure>(InvalidCredentials()),
      );
      expect(identity.current, isNull);
    });

    test('a full keychain does not stop a courier signing in', () async {
      // The session is usable for this run whether or not it survives a
      // restart. Failing here would turn a storage problem into an outage.
      gateway.accept(credentials);
      store.failNextWith(const IdentityUnavailable(detail: 'keychain full'));

      final result = await identity.signIn(credentials);

      expect(result.isSuccess, isTrue);
      expect(identity.current, isNotNull);
      expect(
        logger.records.map((record) => record.message),
        contains(
          'session obtained but not stored; it will not survive a '
          'restart',
        ),
      );
    });
  });

  group('restoring at start-up', () {
    test('adopts a stored session that still holds', () async {
      final session = SessionBuilder().build();
      store.seed(session);

      expect(
        await identity.restore(),
        Success<Session?, IdentityFailure>(session),
      );
      expect(identity.current, session);
    });

    test('nothing stored is a successful nothing', () async {
      expect(
        await identity.restore(),
        const Success<Session?, IdentityFailure>(null),
      );
    });

    test('discards a session whose device fingerprint has changed', () async {
      // The specification's second rule, at the moment it matters: a reinstall
      // or a copied token both look like this, and neither can be told from
      // the other, so the session goes.
      store.seed(SessionBuilder().build());
      devices.binding = SessionBuilder()
          .onDevice('handset-1', fingerprint: 'sha256:different')
          .buildBinding();

      final result = await identity.restore();

      expect(
        result.fold((_) => null, (failure) => failure),
        isA<DeviceBindingBroken>(),
      );
      expect(identity.current, isNull);
      expect(
        store.current,
        isNull,
        reason:
            'a session that no longer holds is discarded, not kept around '
            'to fail on the first request',
      );
    });

    test('discards a session past its refresh window', () async {
      store.seed(
        SessionBuilder()
            .tokenLife(const Duration(minutes: -1))
            .refreshWindow(const Duration(minutes: -1))
            .build(),
      );

      final result = await identity.restore();

      expect(
        result.fold((_) => null, (failure) => failure),
        const SessionExpired(),
      );
      expect(store.current, isNull);
    });
  });

  group('refreshing', () {
    test('refreshIfDue does nothing while the token is comfortable', () async {
      gateway.accept(credentials);
      await identity.signIn(credentials);

      final result = await identity.refreshIfDue();

      expect(result.isSuccess, isTrue);
      expect(gateway.refreshCount, 0);
    });

    test(
      'refreshIfDue refreshes once the token is inside the threshold',
      () async {
        gateway.accept(
          credentials,
          session: SessionBuilder()
              .tokenLife(const Duration(minutes: 4))
              .build(),
        );
        await identity.signIn(credentials);

        final result = await identity.refreshIfDue();

        expect(result.isSuccess, isTrue);
        expect(gateway.refreshCount, 1);
        expect(identity.current?.accessToken.value, 'jwt.refreshed.1');
      },
    );

    test(
      'a session past its refresh window is discarded, not refreshed',
      () async {
        gateway.accept(
          credentials,
          session: SessionBuilder()
              .tokenLife(const Duration(minutes: -1))
              .refreshWindow(const Duration(minutes: -1))
              .build(),
        );
        await identity.signIn(credentials);

        expect(
          await identity.refreshSession(),
          const Failed<Session, IdentityFailure>(SessionExpired()),
        );
        expect(gateway.refreshCount, 0);
        expect(identity.current, isNull);
      },
    );

    test(
      'refreshing with nobody signed in is NoSession, not a crash',
      () async {
        expect(
          await identity.refreshSession(),
          const Failed<Session, IdentityFailure>(NoSession()),
        );
      },
    );
  });

  group('signing out', () {
    test('revokes remotely, clears locally and forgets the session', () async {
      gateway.accept(credentials);
      await identity.signIn(credentials);

      expect((await identity.signOut()).isSuccess, isTrue);
      expect(gateway.revoked, hasLength(1));
      expect(identity.current, isNull);
      expect(store.current, isNull);
    });

    test('signs out locally even when the server cannot be told', () async {
      // Sign-out is what a user reaches for when something is already wrong.
      gateway.accept(credentials);
      await identity.signIn(credentials);
      gateway.failNextWith(const IdentityUnavailable());

      expect((await identity.signOut()).isSuccess, isTrue);
      expect(identity.current, isNull);
      expect(
        logger.records.map((record) => record.message),
        contains('signed out locally without revoking remotely'),
      );
    });

    test('signing out with nobody signed in succeeds', () async {
      expect((await identity.signOut()).isSuccess, isTrue);
    });
  });

  group('what other features see', () {
    test('PermissionChecker answers false when nobody is signed in', () async {
      for (final permission in Permission.values) {
        expect(identity.can(permission), isFalse);
      }
    });

    test('PermissionChecker follows the session', () async {
      gateway.accept(
        credentials,
        session: SessionBuilder().withRoles({Role.dispatcher}).build(),
      );
      await identity.signIn(credentials);

      expect(identity.can(Permission.bulkAssignShipments), isTrue);
      expect(identity.can(Permission.collectPayment), isFalse);

      await identity.signOut();
      expect(identity.can(Permission.bulkAssignShipments), isFalse);
    });

    test('SessionReader and the facade see the same session', () async {
      // Three ports, one fact. Splitting them across three objects would mean
      // three copies of "the session right now", and the first time they
      // disagreed a dispatcher would see a button their permissions no longer
      // allow.
      gateway.accept(credentials);

      final seen = <Session?>[];
      final subscription = identity.changes().listen(seen.add);
      addTearDown(subscription.cancel);

      await identity.signIn(credentials);
      await pumpEventQueue();

      expect(seen.single, identity.current);
    });
  });
}
