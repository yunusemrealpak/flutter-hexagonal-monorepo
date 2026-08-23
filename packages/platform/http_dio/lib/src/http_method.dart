/// The verbs the transport supports.
///
/// A closed set rather than a `String`, so that a caller cannot invent a
/// method the adapter has never been tested against and so that the adapter's
/// translation to the wire is exhaustive.
enum HttpMethod {
  /// Reads a resource.
  get,

  /// Creates a resource, or submits a command.
  post,

  /// Replaces a resource in full.
  put,

  /// Changes part of a resource.
  patch,

  /// Removes a resource.
  delete,
}
