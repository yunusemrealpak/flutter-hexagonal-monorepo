import 'http_method.dart';

/// What the caller wants sent.
///
/// Deliberately transport-shaped and not domain-shaped: a path, a verb, some
/// headers and an opaque body. It carries no notion of a shipment, an actor or
/// a payment, because the package that builds one of these — a feature's
/// `_infrastructure` — is the only place that knows how a domain concept turns
/// into a request, and the only place that should.
///
/// [path] is relative to whatever base the adapter was configured with. The
/// base URL, the auth header and the retry policy are the adapter's business,
/// not the caller's; a request that spelled out its own host would make every
/// call site a place where the environment could be got wrong.
final class HttpRequest {
  /// Describes a call to [path] using [method].
  const HttpRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.headers = const {},
    this.body,
  });

  /// The verb.
  final HttpMethod method;

  /// The path, relative to the adapter's configured base.
  final String path;

  /// Query parameters, already stringified.
  final Map<String, String> query;

  /// Request headers. The adapter adds its own — content type, authorization,
  /// tracing — and does not expect to find them here.
  final Map<String, String> headers;

  /// The payload, or `null` for a request that carries none.
  ///
  /// `Object?` rather than `String`, because the adapter owns encoding: a map
  /// becomes JSON, a byte list is sent as-is. A caller that pre-encodes has
  /// taken a decision that belongs one layer down.
  final Object? body;

  @override
  String toString() => 'HttpRequest(${method.name.toUpperCase()} $path)';
}
