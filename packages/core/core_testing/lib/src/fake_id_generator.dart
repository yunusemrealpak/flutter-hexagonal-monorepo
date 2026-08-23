import 'package:core_ports/core_ports.dart';

/// An [IdGenerator] that produces predictable identifiers.
///
/// Two modes, because tests need two different things. By default it counts —
/// `id-1`, `id-2` — which is enough whenever the test only needs identifiers
/// to be distinct. Given a script, it hands out exactly those values in order,
/// which is what a test asserting on a specific identifier needs.
final class FakeIdGenerator implements IdGenerator {
  /// Counts upwards, producing `<prefix>-1`, `<prefix>-2`, and so on.
  FakeIdGenerator([this._prefix = 'id']) : _scripted = null;

  /// Hands out [ids] in order.
  ///
  /// Running past the end throws rather than wrapping or inventing a value: a
  /// test that asked for three identifiers and used four has a bug in the test
  /// or in the code, and silently supplying a fourth would hide it.
  FakeIdGenerator.scripted(List<String> ids)
    : _prefix = 'id',
      _scripted = List<String>.of(ids);

  final String _prefix;
  final List<String>? _scripted;
  int _issued = 0;

  /// How many identifiers have been handed out.
  ///
  /// The assertion for "this use case generated exactly one idempotency key,
  /// however many times it retried".
  int get issuedCount => _issued;

  @override
  String newId() {
    final scripted = _scripted;
    if (scripted != null) {
      if (_issued >= scripted.length) {
        throw StateError(
          'FakeIdGenerator.scripted ran out after ${scripted.length} ids',
        );
      }
      return scripted[_issued++];
    }
    _issued++;
    return '$_prefix-$_issued';
  }
}
