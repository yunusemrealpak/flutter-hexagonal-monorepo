@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:test/test.dart';

final _noon = DateTime.utc(2026, 3, 14, 12);

AccessToken _token({required DateTime expiresAt, String value = 'jwt.abc'}) =>
    switch (AccessToken.issue(value: value, expiresAt: expiresAt)) {
      Success(value: final token) => token,
      Failed(:final failure) => throw StateError('$failure'),
    };

void main() {
  group('AccessToken.issue', () {
    test('refuses an empty token', () {
      expect(
        AccessToken.issue(value: '   ', expiresAt: _noon),
        const Failed<AccessToken, IdentityFailure>(
          MalformedAccessToken('empty'),
        ),
      );
    });

    test('refuses a local expiry', () {
      // A local DateTime compared against the UTC one the Clock port promises
      // is off by the device's offset, so it is refused at the edge rather
      // than converted silently.
      expect(
        AccessToken.issue(
          value: 'jwt.abc',
          expiresAt: DateTime(2026, 3, 14, 12),
        ),
        const Failed<AccessToken, IdentityFailure>(
          MalformedAccessToken('expiry is not UTC'),
        ),
      );
    });
  });

  group('expiry', () {
    test('is not expired before the instant', () {
      final token = _token(expiresAt: _noon);

      expect(
        token.hasExpiredAt(_noon.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('is expired at the instant, not after it', () {
      final token = _token(expiresAt: _noon);

      expect(token.hasExpiredAt(_noon), isTrue);
    });
  });

  group('refresh threshold', () {
    test('is not due while the token has more than the threshold left', () {
      final token = _token(expiresAt: _noon.add(const Duration(minutes: 10)));

      expect(
        token.needsRefreshAt(_noon, threshold: const Duration(minutes: 5)),
        isFalse,
      );
    });

    test('is due once the token is inside the threshold', () {
      final token = _token(expiresAt: _noon.add(const Duration(minutes: 4)));

      expect(
        token.needsRefreshAt(_noon, threshold: const Duration(minutes: 5)),
        isTrue,
      );
    });

    test('is due for an already expired token', () {
      final token = _token(expiresAt: _noon.subtract(const Duration(hours: 1)));

      expect(
        token.needsRefreshAt(_noon, threshold: const Duration(minutes: 5)),
        isTrue,
      );
    });
  });

  group('equality and printing', () {
    test('same text and same expiry is the same token', () {
      expect(_token(expiresAt: _noon), _token(expiresAt: _noon));
      expect(
        _token(expiresAt: _noon).hashCode,
        _token(expiresAt: _noon).hashCode,
      );
    });

    test('a re-issued token is a different token', () {
      expect(
        _token(expiresAt: _noon, value: 'jwt.new'),
        isNot(_token(expiresAt: _noon)),
      );
    });

    test('toString never prints the token', () {
      final printed = _token(
        expiresAt: _noon,
        value: 'super-secret',
      ).toString();

      expect(printed, isNot(contains('super-secret')));
      expect(printed, contains('2026-03-14'));
    });
  });
}
