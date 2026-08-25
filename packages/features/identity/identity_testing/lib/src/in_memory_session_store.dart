import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

/// A `SessionStore` that really stores, in a field.
///
/// A miss is `Success(null)`, not a failure: an empty store is the ordinary
/// state of a fresh install, and reporting it as a failure would put a failure
/// branch on the happy path of every first launch.
final class InMemorySessionStore implements SessionStore {
  Session? _stored;
  final List<IdentityFailure> _queuedFailures = [];

  /// Makes the next call return [failure]. Queue several to fail several.
  void failNextWith(IdentityFailure failure) => _queuedFailures.add(failure);

  /// What the store currently holds, for a test that wants to look.
  Session? get current => _stored;

  /// Puts a session in place without going through [write].
  ///
  /// For arranging a test, not for use by the code under test — which is why
  /// it stays a method rather than becoming a setter that reads like part of
  /// the port.
  // ignore: use_setters_to_change_properties
  void seed(Session session) => _stored = session;

  @override
  Future<Result<Session?, IdentityFailure>> read() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);
    return Success(_stored);
  }

  @override
  Future<Result<void, IdentityFailure>> write(Session session) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);
    _stored = session;
    return const Success(null);
  }

  @override
  Future<Result<void, IdentityFailure>> clear() async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);
    _stored = null;
    return const Success(null);
  }

  IdentityFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
