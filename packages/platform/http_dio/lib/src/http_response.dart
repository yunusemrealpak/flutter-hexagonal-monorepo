/// What came back.
///
/// A status, some headers and a decoded body. Nothing here interprets the
/// status: `HttpTransport` decides which statuses are a failure, and the
/// feature adapter that called it decides what a particular failure means for
/// its domain.
final class HttpResponse {
  /// Records a response with [statusCode] and [body].
  const HttpResponse({
    required this.statusCode,
    this.body,
    this.headers = const {},
  });

  /// The HTTP status.
  final int statusCode;

  /// The decoded payload, or `null` when the response had no body.
  ///
  /// JSON arrives as the maps and lists it decodes to; anything else arrives
  /// as the adapter received it.
  final Object? body;

  /// Response headers. A header may legitimately appear more than once, so the
  /// value is a list rather than a string.
  final Map<String, List<String>> headers;

  @override
  String toString() => 'HttpResponse($statusCode)';
}
