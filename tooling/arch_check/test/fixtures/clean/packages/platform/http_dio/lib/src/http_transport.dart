/// A technology contract: it speaks in a technology's words, so it lives here
/// rather than in core_ports.
abstract interface class HttpTransport {
  /// Performs a GET and returns the decoded body.
  Future<Map<String, dynamic>?> get(String path);
}
