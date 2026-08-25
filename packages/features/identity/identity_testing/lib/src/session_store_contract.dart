import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

import 'session_builder.dart';

/// The behaviour every `SessionStore` has to have, whatever is behind it.
///
/// Run from here against `InMemorySessionStore` and from
/// `identity_infrastructure` against the keychain-backed one. A session store
/// is the piece most likely to be reimplemented per platform, and it is the
/// piece where a behavioural difference is least visible — an app that quietly
/// forgot a session on restart looks like a login bug, not a storage bug.
///
/// [createStore] must return a fresh, empty store on every call.
void runSessionStoreContract(SessionStore Function() createStore) {
  group('SessionStore contract', () {
    late SessionStore store;

    setUp(() => store = createStore());

    test('an empty store reads as a successful null', () async {
      // Not a failure. A fresh install has no session, and reporting that as
      // a failure would put a failure branch on the happy path of every first
      // launch.
      expect(
        await store.read(),
        const Success<Session?, IdentityFailure>(null),
      );
    });

    test('reads back what was written', () async {
      final session = SessionBuilder().build();
      await store.write(session);

      expect(
        await store.read(),
        Success<Session?, IdentityFailure>(session),
      );
    });

    test('a write replaces rather than accumulating', () async {
      await store.write(SessionBuilder().withToken('first').build());
      final second = SessionBuilder().withToken('second').build();
      await store.write(second);

      final read = await store.read();
      expect(
        read.fold((s) => s?.accessToken.value, (f) => throw StateError('$f')),
        'second',
      );
    });

    test(
      'clear empties it, and succeeds when there is nothing to clear',
      () async {
        await store.write(SessionBuilder().build());

        expect((await store.clear()).isSuccess, isTrue);
        expect(
          await store.read(),
          const Success<Session?, IdentityFailure>(null),
        );
        expect(
          (await store.clear()).isSuccess,
          isTrue,
          reason:
              'sign-out is what a user reaches for when something is '
              'already wrong; failing it strands them',
        );
      },
    );

    test('a stored session keeps everything that decides a rule', () async {
      // The fields the two business rules read. A store that dropped the
      // refresh window or the device fingerprint would produce an app that
      // signs people out at apparently random moments.
      final session = SessionBuilder()
          .actor('courier-9', displayName: 'Zeynep')
          .withRoles({Role.dispatcher})
          .granting(Permission.refundPayment)
          .tokenLife(const Duration(minutes: 42))
          .refreshWindow(const Duration(days: 3))
          .onDevice('handset-9', fingerprint: 'sha256:zzz')
          .build();
      await store.write(session);

      final read = await store.read();
      final stored = read.fold((s) => s!, (f) => throw StateError('$f'));

      expect(stored.actor.id, session.actor.id);
      expect(stored.actor.displayName, 'Zeynep');
      expect(stored.actor.can(Permission.refundPayment), isTrue);
      expect(stored.accessToken.expiresAt, session.accessToken.expiresAt);
      expect(stored.refreshableUntil, session.refreshableUntil);
      expect(stored.deviceBinding, session.deviceBinding);
    });

    test('the port never throws', () async {
      expect((await store.read()).isSuccess, isTrue);
      expect((await store.clear()).isSuccess, isTrue);
      expect(
        (await store.write(SessionBuilder().build())).isSuccess,
        isTrue,
      );
    });
  });
}
