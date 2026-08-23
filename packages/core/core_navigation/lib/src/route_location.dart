import 'package:core_kernel/core_kernel.dart';

/// A concrete destination: where to go, not how to draw it.
///
/// A [ValueObject] over the encoded location string, so two locations built
/// from the same path and the same parameters are equal however they were
/// constructed. That matters because navigation is frequently deduplicated —
/// a double tap must not push the same screen twice — and comparing by value
/// is what makes that check trivial.
///
/// Query parameters are sorted before encoding. Without that, the same
/// destination built from two differently ordered maps would compare unequal,
/// and the deduplication above would silently stop working.
final class RouteLocation extends ValueObject<String> {
  /// Builds a location for [path] with optional [queryParameters].
  RouteLocation(this.path, {this.queryParameters = const {}})
    : super(_encode(path, queryParameters));

  /// The path portion, always starting with `/`.
  final String path;

  /// The query parameters, in whatever order the caller supplied them.
  final Map<String, String> queryParameters;

  static String _encode(String path, Map<String, String> query) {
    if (query.isEmpty) {
      return path;
    }
    final keys = query.keys.toList()..sort();
    final pairs = keys.map(
      (key) =>
          '${Uri.encodeQueryComponent(key)}'
          '=${Uri.encodeQueryComponent(query[key]!)}',
    );
    return '$path?${pairs.join('&')}';
  }
}
