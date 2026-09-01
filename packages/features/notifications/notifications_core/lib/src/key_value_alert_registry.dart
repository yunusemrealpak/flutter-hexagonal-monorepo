import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:notifications_api/notifications_api.dart';

/// Keeps what this device remembers about opening alerts, in a key-value
/// store.
///
/// The smallest adapter in the feature, and the one that carries the most
/// weight per line: everything the product can say about whether alerts are on
/// rests on a flag nothing outside this device can produce.
///
/// It never sees `identity_api`: `AlertRegistry` promises a `String`, and an
/// adapter that took an `ActorId` would be one that could not move into an
/// `_infrastructure` package the day this feature splits.
///
/// One key per actor rather than one key holding a set. The question is always
/// asked about one person — the one signed in — so a set would be read whole
/// to answer a question about a single member, and would have to be rewritten
/// whole to change it.
///
/// **Absence is the answer, not a hole in it.** A key nobody wrote means this
/// device never opened alerts for that actor, which is exactly what a fresh
/// handset should say. Only a store that cannot be reached fails.
final class KeyValueAlertRegistry implements AlertRegistry {
  /// Creates the adapter over the store it keeps the flags in.
  const KeyValueAlertRegistry({required this._store});

  final KeyValueStore _store;

  /// The prefix every key this adapter writes carries.
  ///
  /// A namespace rather than a bare actor identifier, for the reason
  /// `KeyValueInboxStore` gives: the store is shared with every other feature
  /// that keeps a scalar, and two features choosing the same key would
  /// silently overwrite each other.
  static const keyPrefix = 'notifications.alerts.';

  /// The value written for an open registration.
  ///
  /// The value is never parsed — presence is the fact — but writing something
  /// readable is what makes a store dump legible to whoever is debugging why a
  /// courier stopped being alerted.
  static const _open = 'open';

  @override
  Future<Result<bool, NotificationsFailure>> isOpenFor(String actorId) async {
    final read = await _store.read(_keyFor(actorId));
    return read.fold(
      (value) => Success(value != null),
      (failure) => Failed(AlertStateUnavailable(detail: failure.toString())),
    );
  }

  @override
  Future<Result<void, NotificationsFailure>> rememberOpen(
    String actorId,
  ) async {
    final written = await _store.write(_keyFor(actorId), _open);
    return written.mapFailure(
      (failure) => AlertStateUnavailable(detail: failure.toString()),
    );
  }

  @override
  Future<Result<void, NotificationsFailure>> forget(String actorId) async {
    final deleted = await _store.delete(_keyFor(actorId));
    return deleted.mapFailure(
      (failure) => AlertStateUnavailable(detail: failure.toString()),
    );
  }

  String _keyFor(String actorId) => '$keyPrefix$actorId';
}
