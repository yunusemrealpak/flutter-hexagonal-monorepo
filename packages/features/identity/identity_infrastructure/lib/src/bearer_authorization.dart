import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';

/// Answers the transport's `AuthorizationProvider` out of identity's session.
///
/// The join the workspace was missing, and the only package entitled to make
/// it. §1.1 forbids a `platform/*` package from depending on a feature, so
/// `http_dio` cannot ask identity for a token; §1.1 also gives
/// `<feature>_infrastructure` both `platform/*` and its own `_api`, so this is
/// the one row in the table that can see the contract and the session at once.
/// An app could do it too — an app may depend on anything — but it would be
/// one copy per application of a translation neither of them decides anything
/// about.
///
/// Its whole content is the two lines that turn a token into a header value,
/// which is the point: the *scheme* is knowledge about how identity's server
/// wants to be addressed, and it already lived in this package —
/// `DeviceBoundCredentialGateway` writes the same `Bearer` prefix when it
/// refreshes. Putting it in the interceptor instead would have spread one
/// server's convention into a package that must not know whose server it is.
///
/// **Nothing here decides when to refresh**, and that is deliberate. The
/// timing rule is `Session.needsRefreshAt` in `identity_api`, acted on by
/// `IdentityCoordinator.refreshIfDue`, and reached through `SessionTokens`.
/// An adapter that re-derived it would be a second place the threshold lives,
/// and the two would disagree the first time one of them changed.
final class BearerAuthorization implements AuthorizationProvider {
  /// Presents what `tokens` hands over, reporting refusals to `logger`.
  const BearerAuthorization({required this._tokens, required this._logger});

  /// The authentication scheme the operation's API accepts.
  static const String scheme = 'Bearer';

  final SessionTokens _tokens;
  final Logger _logger;

  @override
  Future<String?> credential() async =>
      _header(await _tokens.presentable(), attempting: 'authorize a request');

  @override
  Future<String?> renewedCredential() async =>
      _header(await _tokens.renewed(), attempting: 'renew a refused token');

  /// Turns a token into a header value, and a failure into `null` and a log
  /// line.
  ///
  /// The port returns `String?` rather than a `Result` because its caller — an
  /// interceptor — can do nothing with the reason. That does not make the
  /// reason worthless, only useless *there*: it is the difference between "no
  /// session, as expected on the sign-in screen" and "the keychain could not
  /// be read", and this is the last place that can tell them apart.
  String? _header(
    Result<AccessToken, IdentityFailure> result, {
    required String attempting,
  }) => result.fold((token) => '$scheme ${token.value}', (failure) {
    _logger.log(
      // Nobody being signed in is the ordinary state of an app on its sign-in
      // screen, and logging it as a warning would bury the cases that are not
      // ordinary under the one that always happens.
      failure is NoSession ? LogLevel.debug : LogLevel.warning,
      'no credential available to $attempting',
      // The failure's own `toString`, and never the token: `AccessToken`
      // redacts for exactly this reason and a wider context here would undo
      // it.
      context: {'failure': '$failure'},
    );
    return null;
  });
}
