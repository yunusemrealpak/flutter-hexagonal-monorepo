import 'package:core_ports/core_ports.dart';
import 'package:dio/dio.dart';

import 'authorization_interceptor.dart';
import 'authorization_provider.dart';
import 'observability_interceptor.dart';
import 'retry_interceptor.dart';

/// How a Peyk application configures the client it sends through.
///
/// The composition root still owns the environment — [optionsFor] takes the
/// base URL and this package holds no default for it, which is the rule the
/// README states and the reason a call site can never address the wrong
/// operation. What is *not* an environment decision is the timeout policy and
/// the order of the interceptor chain, and leaving those to each app produced
/// the two defects this class exists to prevent.
///
/// **A Dio built with no timeouts waits forever.** Both applications
/// constructed `Dio(BaseOptions(baseUrl: …))` and nothing else, so
/// `connectTimeout`, `sendTimeout` and `receiveTimeout` were all null — Dio's
/// documented meaning for "no timeout at all". `TransportTimeout` was a case
/// in a sealed hierarchy that production could not produce, every adapter
/// translated it, and a courier in a tunnel would have watched a spinner until
/// the OS gave up on the socket.
///
/// **The chain's order is a correctness property, not a preference.** It is
/// stated once, here, with the reasons attached.
final class PeykTransport {
  const PeykTransport._();

  /// How long a connection may take to establish.
  ///
  /// Short. Failing to reach a host is the failure a courier's phone hits
  /// constantly, and `sync` already knows what to do about it: queue the work
  /// and drain when connectivity returns. Waiting thirty seconds first only
  /// delays that.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// How long the request body may take to send.
  ///
  /// Longer than [connectTimeout], because a proof of delivery carries a
  /// photograph and an edge connection is slow rather than absent.
  static const Duration sendTimeout = Duration(seconds: 30);

  /// How long the response may take to arrive in full.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// The options every Peyk application's client is built from.
  ///
  /// [baseUrl] is required and has no default on purpose: an environment this
  /// package could supply is an environment a call site could get wrong.
  static BaseOptions optionsFor(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
  );

  /// Installs the chain on [dio], in the order it has to run in.
  ///
  /// Called after the container is built, because two of the three
  /// interceptors need things the container holds and the authorising one
  /// needs the client itself in order to replay.
  ///
  /// The order:
  ///
  /// 1. **Observability first**, so that its `onRequest` stamps the
  ///    correlation identifier before anything else can read one and its
  ///    `onResponse` sees every attempt. Placed later it would log the
  ///    surviving attempt and hide the retries, which is the opposite of what
  ///    it is for.
  /// 2. **Authorization second**, so the credential is attached to the request
  ///    the identifier is already on, and so a 401 is answered by a renewal
  ///    before anything treats it as an ordinary refusal.
  /// 3. **Retry last**, because it is the only one that should ever see a
  ///    request twice for a reason that is not authentication. It ignores 401
  ///    deliberately — a refused credential is not transient, and retrying one
  ///    would burn the attempt budget on a request that cannot succeed.
  static void installOn(
    Dio dio, {
    required AuthorizationProvider authorization,
    required Logger logger,
    required IdGenerator ids,
    required Clock clock,
    required RandomSource random,
  }) => dio.interceptors.addAll([
    ObservabilityInterceptor(logger: logger, ids: ids, clock: clock),
    AuthorizationInterceptor(
      dio: dio,
      provider: authorization,
      logger: logger,
    ),
    RetryInterceptor(dio: dio, random: random, logger: logger),
  ]);
}
