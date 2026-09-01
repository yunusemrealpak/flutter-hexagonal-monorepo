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

  group('the token the outbound transport presents', () {
    test('hands over the current token while it is comfortable', () async {
      gateway.accept(credentials);
      await identity.signIn(credentials);

      final result = await identity.presentable();

      expect(
        result.fold((token) => token.value, (failure) => '$failure'),
        identity.current?.accessToken.value,
      );
      expect(gateway.refreshCount, 0);
    });

    test('refreshes first when the token is inside the threshold', () async {
      // The whole reason the port exists. Waiting for the 401 works, but it
      // costs a failed round trip on the connection that is already the reason
      // the app feels slow.
      gateway.accept(
        credentials,
        session: SessionBuilder().tokenLife(const Duration(minutes: 4)).build(),
      );
      await identity.signIn(credentials);

      final result = await identity.presentable();

      expect(
        result.fold((token) => token.value, (failure) => '$failure'),
        'jwt.refreshed.1',
      );
      expect(gateway.refreshCount, 1);
    });

    test('answers NoSession rather than a token nobody holds', () async {
      // The ordinary state of an app on its sign-in screen, which is why the
      // adapter above this logs it at debug and sends the request without a
      // credential rather than refusing to send it.
      expect(
        await identity.presentable(),
        const Failed<AccessToken, IdentityFailure>(NoSession()),
      );
    });

    test('renewing refreshes a token that still looks comfortable', () async {
      // `renewed` is called after the server has said the token is not
      // accepted. Consulting `needsRefreshAt` here would answer a 401 with the
      // token that caused it whenever the two clocks disagree — and disagreeing
      // clocks are exactly when this path runs.
      gateway.accept(credentials);
      await identity.signIn(credentials);

      final result = await identity.renewed();

      expect(
        result.fold((token) => token.value, (failure) => '$failure'),
        'jwt.refreshed.1',
      );
      expect(gateway.refreshCount, 1);
    });

    test('ten requests arriving at once produce one refresh', () async {
      // A server that rotates refresh tokens invalidates the other nine, so
      // the last one wins and nine sessions die. The collapse belongs here
      // rather than in the interceptor that noticed the problem: not
      // refreshing a session twice at once is a statement about the session.
      gateway.accept(
        credentials,
        session: SessionBuilder().tokenLife(const Duration(minutes: 4)).build(),
      );
      await identity.signIn(credentials);

      final results = await Future.wait([
        for (var i = 0; i < 10; i++) identity.presentable(),
      ]);

      expect(gateway.refreshCount, 1);
      expect(
        results
            .map((it) => it.fold((token) => token.value, (f) => '$f'))
            .toSet(),
        {'jwt.refreshed.1'},
      );
    });

    test('a later refresh is a new one, not the finished one', () async {
      // The in-flight future has to be released when it completes. Keeping it
      // would make the second expiry of the day unrefreshable.
      gateway.accept(credentials);
      await identity.signIn(credentials);

      await identity.renewed();
      await identity.renewed();

      expect(gateway.refreshCount, 2);
    });
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
