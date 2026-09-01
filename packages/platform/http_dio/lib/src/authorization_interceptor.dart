import 'package:core_ports/core_ports.dart';
import 'package:dio/dio.dart';

import 'authorization_provider.dart';

/// Attaches the credential to every outbound request, and replays a request
/// the server refused once with a renewed one.
///
/// This is the seam the workspace was missing: before it existed, every
/// gateway outside identity's own two sent `HttpRequest(method:, path:)` with
/// no headers, and `HttpRequest.headers`' doc comment — *"the adapter adds its
/// own — content type, authorization, tracing"* — described an adapter that
/// added nothing. Against a real backend that is a 401 on every call.
///
/// **Why an interceptor and not a decorator over `HttpTransport`.** The
/// contract already assigns the header to the adapter, in so many words, so a
/// decorator sitting *above* `HttpTransport` would be contradicting the
/// interface it wraps. Placing it below also keeps the replay honest: a
/// decorator retrying a refused request would re-run the caller's own mapping
/// and hand the gateway two chances to decode, whereas this replays the
/// request Dio already built.
///
/// **Two guards keep it from eating itself**, and both are rules about the
/// request rather than about a path — a path list here would make this package
/// know identity's URL layout, which is exactly the dependency §1.1 forbids:
///
/// - **A request that carries its own `Authorization` is left alone.** That is
///   identity refreshing or revoking a session; it holds a credential this
///   provider cannot supply, and overwriting it would replace a refresh token
///   with the access token that just expired.
/// - **A replayed request is never replayed again.** Marked in
///   [replayedFlag] on `RequestOptions.extra`, which survives the second trip
///   through this interceptor and answers "have I already tried" without any
///   state held here.
///
/// **The 401 is handled in [onResponse] rather than in `onError`, and that is
/// not a style choice.** `DioHttpTransport` sends with `validateStatus: (_) =>
/// true` so that a 4xx keeps its body, so no status ever becomes a
/// `DioException` and `onError` never sees one. An implementation that put the
/// refresh in `onError` would compile, pass a hand-written Dio test, and never
/// fire in this workspace.
///
/// **It is a plain [Interceptor] and deliberately not a `QueuedInterceptor`.**
/// Queuing looks like the answer to a token expiring under ten concurrent
/// requests, and it deadlocks: `QueuedInterceptor` serialises response
/// handling on one queue, and the replay's own response has to pass through
/// that same queue while the handler awaiting it still holds it. Collapsing
/// concurrent renewals is the *provider's* job — [AuthorizationProvider]
/// requires it in writing — and it belongs there anyway, because "do not
/// refresh a session twice at once" is a rule about the session.
final class AuthorizationInterceptor extends Interceptor {
  /// Authorises everything sent through `dio`, using `provider`.
  ///
  /// The client is the one this interceptor is installed on, which it needs in
  /// order to replay. Constructing the interceptor after the client and adding
  /// it afterwards is the only order that works, and it is what a composition
  /// root does anyway.
  AuthorizationInterceptor({
    required this._dio,
    required this._provider,
    required this._logger,
  });

  /// The header this interceptor owns.
  static const String header = 'Authorization';

  /// The `RequestOptions.extra` key marking a request as already replayed.
  ///
  /// Namespaced, because `extra` is shared with every other interceptor and
  /// with Dio itself.
  static const String replayedFlag = 'peyk.authorization.replayed';

  /// The `RequestOptions.extra` key marking a credential as *this*
  /// interceptor's work.
  ///
  /// The presence of the header alone cannot answer that question, because a
  /// replay sets the header too — so a check that read the header would treat
  /// its own second attempt as somebody else's credential and refuse to
  /// renew. It also separates the two reasons a request has no credential of
  /// ours: identity supplied its own, or nobody is signed in. Only the second
  /// makes a 401 worth renewing over, and only the first must never be
  /// overwritten.
  static const String attachedFlag = 'peyk.authorization.attached';

  final Dio _dio;
  final AuthorizationProvider _provider;
  final Logger _logger;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Whoever put a credential here keeps it: identity refreshing its own
    // session on the way out, or this interceptor replaying on the way back.
    if (_hasCredential(options)) {
      return handler.next(options);
    }

    final credential = await _provider.credential();
    if (credential != null) {
      options.headers[header] = credential;
      options.extra[attachedFlag] = true;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (response.statusCode != 401 || !_mayReplay(options)) {
      return handler.next(response);
    }

    final renewed = await _provider.renewedCredential();
    if (renewed == null) {
      // Nothing left to try. The 401 goes on to the caller unchanged, which is
      // what turns into `TransportRejected(401)` and, in identity's own
      // translation, into the sign-in screen.
      _logger.info(
        'request refused and no credential could be renewed',
        context: {'path': options.path},
      );
      return handler.next(response);
    }

    options.headers[header] = renewed;
    options.extra[replayedFlag] = true;

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (error) {
      // The replay itself failed at the transport level — the connection went
      // away between the two attempts. Rejecting with the second error rather
      // than resolving with the first 401 keeps the reason accurate: the
      // caller is offline, not unauthorised.
      handler.reject(error);
    }
  }

  /// Whether the request already carries a credential, whoever put it there.
  ///
  /// `RequestOptions.headers` is a case-insensitive map, so a gateway that
  /// spelled the header in lower case is found by this and — more to the point
  /// — is overwritten rather than duplicated by the assignment above.
  static bool _hasCredential(RequestOptions options) =>
      options.headers.containsKey(header);

  /// Whether a 401 on this request is worth renewing a credential over.
  ///
  /// Only when the refused credential was one this interceptor attached. A
  /// request identity authorised itself owns its outcome — replaying its
  /// refresh call with an access token would send the wrong secret to the one
  /// endpoint that can tell — and a request that carried nothing was refused
  /// for a reason no credential fixes.
  static bool _mayReplay(RequestOptions options) =>
      options.extra[replayedFlag] != true &&
      options.extra[attachedFlag] == true;
}
