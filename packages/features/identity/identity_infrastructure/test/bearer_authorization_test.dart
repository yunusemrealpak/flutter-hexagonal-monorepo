@Tags(['unit'])
library;

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:test/test.dart';

/// A [SessionTokens] whose two answers the test states outright.
///
/// Written here rather than taken from `identity_testing` because it stands in
/// for a port this package *consumes* in one adapter, and because the whole
/// content of that adapter is which of the two answers it asked for. A fake
/// that could not be told to answer them differently could not prove it.
final class _ScriptedTokens implements SessionTokens {
  _ScriptedTokens({required this.forPresenting, required this.forRenewing});

  Result<AccessToken, IdentityFailure> forPresenting;
  Result<AccessToken, IdentityFailure> forRenewing;

  @override
  Future<Result<AccessToken, IdentityFailure>> presentable() async =>
      forPresenting;

  @override
  Future<Result<AccessToken, IdentityFailure>> renewed() async => forRenewing;
}

Result<AccessToken, IdentityFailure> _token(String value) => AccessToken.issue(
  value: value,
  expiresAt: DateTime.utc(2026, 1, 1, 10),
);

void main() {
  late RecordingLogger logger;

  setUp(() => logger = RecordingLogger());

  BearerAuthorization authorizationOver(_ScriptedTokens tokens) =>
      BearerAuthorization(tokens: tokens, logger: logger);

  test('presents the current token in the scheme the API accepts', () async {
    final authorization = authorizationOver(
      _ScriptedTokens(
        forPresenting: _token('jwt.live'),
        forRenewing: const Failed(NoSession()),
      ),
    );

    expect(await authorization.credential(), 'Bearer jwt.live');
  });

  test('asks the other question after the server refused the last', () async {
    // The two calls are not interchangeable, and this is where that shows: a
    // renewal answered from `presentable` would hand back the token the server
    // has already rejected.
    final authorization = authorizationOver(
      _ScriptedTokens(
        forPresenting: _token('jwt.stale'),
        forRenewing: _token('jwt.fresh'),
      ),
    );

    expect(await authorization.renewedCredential(), 'Bearer jwt.fresh');
  });

  test('answers nothing, quietly, when nobody is signed in', () async {
    // The ordinary state of an app on its sign-in screen. Logging it as a
    // warning would bury the cases that are not ordinary under the one that
    // happens on every launch.
    final authorization = authorizationOver(
      _ScriptedTokens(
        forPresenting: const Failed(NoSession()),
        forRenewing: const Failed(NoSession()),
      ),
    );

    expect(await authorization.credential(), isNull);
    expect(logger.records.single.level, LogLevel.debug);
  });

  test('answers nothing, loudly, when something actually went wrong', () async {
    final authorization = authorizationOver(
      _ScriptedTokens(
        forPresenting: const Failed(
          IdentityUnavailable(detail: 'keychain locked'),
        ),
        forRenewing: const Failed(SessionExpired()),
      ),
    );

    expect(await authorization.credential(), isNull);
    expect(logger.records.single.level, LogLevel.warning);

    logger.clear();

    expect(await authorization.renewedCredential(), isNull);
    expect(logger.records.single.level, LogLevel.warning);
  });

  test('never writes a token into the log', () async {
    // `AccessToken.toString` redacts, and this adapter is the place that would
    // undo it — it is the last code that holds the value before it becomes a
    // header.
    final authorization = authorizationOver(
      _ScriptedTokens(
        forPresenting: _token('jwt.secret-value'),
        forRenewing: const Failed(SessionExpired()),
      ),
    );

    await authorization.credential();
    await authorization.renewedCredential();

    expect(
      logger.records.map((it) => '${it.message} ${it.context}'),
      everyElement(isNot(contains('secret-value'))),
    );
  });
}
