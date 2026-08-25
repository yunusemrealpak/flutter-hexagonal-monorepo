@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

final _noon = DateTime.utc(2026, 3, 14, 12);

ActorId _actorId(String raw) =>
    ActorId.parse(raw).fold((id) => id, (f) => throw StateError('$f'));

AccessToken _token(DateTime expiresAt) => AccessToken.issue(
  value: 'jwt.abc',
  expiresAt: expiresAt,
).fold((t) => t, (f) => throw StateError('$f'));

DeviceBinding _binding({String fingerprint = 'sha256:aaa'}) => DeviceBinding(
  deviceId: 'handset-1',
  fingerprint: fingerprint,
  boundAt: _noon.subtract(const Duration(days: 30)),
);

Session _session({
  Duration tokenLife = const Duration(hours: 1),
  Duration refreshWindow = const Duration(days: 7),
  DeviceBinding? binding,
}) => Session(
  actor: Actor(
    id: _actorId('ali'),
    displayName: 'Ali',
    roles: {Role.courier},
  ),
  accessToken: _token(_noon.add(tokenLife)),
  deviceBinding: binding ?? _binding(),
  refreshableUntil: _noon.add(refreshWindow),
);

void main() {
  group('refresh', () {
    test('is not needed while the token is comfortably alive', () {
      expect(_session().needsRefreshAt(_noon), isFalse);
    });

    test('is needed once the token is inside the threshold', () {
      final session = _session(tokenLife: const Duration(minutes: 4));

      expect(session.needsRefreshAt(_noon), isTrue);
    });

    test('is still possible inside the refresh window', () {
      expect(_session().canRefreshAt(_noon), isTrue);
    });

    test('is no longer possible once the window has closed', () {
      final session = _session();

      expect(session.canRefreshAt(_noon.add(const Duration(days: 8))), isFalse);
    });
  });

  group('validateAgainst', () {
    test('returns the session unchanged when the device still matches', () {
      final session = _session();

      expect(
        session.validateAgainst(_binding(), _noon),
        Success<Session, IdentityFailure>(session),
      );
    });

    test('refuses a session whose device fingerprint has changed', () {
      final session = _session();

      expect(
        session.validateAgainst(_binding(fingerprint: 'sha256:bbb'), _noon),
        const Failed<Session, IdentityFailure>(
          DeviceBindingBroken(
            deviceId: 'handset-1',
            expectedFingerprint: 'sha256:aaa',
            actualFingerprint: 'sha256:bbb',
          ),
        ),
      );
    });

    test('refuses a session past its refresh window with a dead token', () {
      final session = _session();

      expect(
        session.validateAgainst(_binding(), _noon.add(const Duration(days: 8))),
        const Failed<Session, IdentityFailure>(SessionExpired()),
      );
    });

    test('accepts a dead token while the refresh window is still open', () {
      // The token being expired is not by itself a reason to sign anybody out
      // — that is what the refresh window is for.
      final session = _session(tokenLife: const Duration(minutes: 1));

      expect(
        session
            .validateAgainst(_binding(), _noon.add(const Duration(hours: 2)))
            .isSuccess,
        isTrue,
      );
    });

    test('reports a broken binding even when the session had also expired', () {
      // Order matters: a session presented on the wrong device is a security
      // event, and reporting it as a plain expiry would hide it in the noise
      // of every ordinary sign-in.
      final session = _session();

      expect(
        session.validateAgainst(
          _binding(fingerprint: 'sha256:bbb'),
          _noon.add(const Duration(days: 8)),
        ),
        isA<Failed<Session, IdentityFailure>>().having(
          (f) => f.failure,
          'failure',
          isA<DeviceBindingBroken>(),
        ),
      );
    });
  });

  group('DeviceBinding.matches', () {
    test('a re-issued binding for the same device still matches', () {
      final original = _binding();
      final reissued = original.copyWith(boundAt: _noon);

      expect(original.matches(reissued), isTrue);
    });

    test('a different device does not match', () {
      expect(
        _binding().matches(_binding().copyWith(deviceId: 'handset-2')),
        isFalse,
      );
    });
  });

  group('value semantics', () {
    test('two sessions with the same contents are the same session', () {
      expect(_session(), _session());
      expect(_session().hashCode, _session().hashCode);
    });

    test('toString does not leak the token', () {
      expect(_session().toString(), isNot(contains('jwt.abc')));
    });
  });
}
