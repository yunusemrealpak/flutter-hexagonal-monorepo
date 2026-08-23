import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:core_ports/core_ports.dart';
import 'network_condition_mapping.dart';

/// The [NetworkStatus] the shipped applications run on.
///
/// ## Why this adapter has a lifecycle when the port does not
///
/// `NetworkStatus.current` is synchronous, because the caller that matters —
/// `sync`, deciding whether a drain is worth attempting — must not have to
/// await an answer inside a loop. The plugin is asynchronous. So the adapter
/// keeps the last observed condition in a field and refreshes it from the
/// plugin's stream, which gives it a [start] and a [dispose] the port knows
/// nothing about. A composition root calls both; no product code ever sees
/// them.
///
/// Before [start] completes, [current] is [NetworkCondition.offline]. That is
/// the conservative direction: work is queued rather than attempted, and a
/// queued item that turns out to have been sendable costs a few seconds, while
/// an attempt made with no connection costs a failed request and a retry
/// schedule.
///
/// ## Reading connectivity cannot fail
///
/// Nothing here returns a `Result`, because the answer to "are we offline?"
/// when the subsystem is unreachable is [NetworkCondition.offline] rather than
/// an error. An exception from the plugin is caught and treated as exactly
/// that.
///
/// Knowing the condition is still not the same as knowing a request will
/// succeed. Adapters keep handling failure; this port only lets `sync` decide
/// whether attempting is worth it at all.
final class ConnectivityMonitor implements NetworkStatus {
  /// Observes through the given platform implementation.
  ConnectivityMonitor(this._platform);

  final ConnectivityPlatform _platform;
  final StreamController<NetworkCondition> _changes =
      StreamController<NetworkCondition>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkCondition _current = NetworkCondition.offline;

  @override
  NetworkCondition get current => _current;

  @override
  Stream<NetworkCondition> changes() {
    // The port promises the current value on subscription, so a listener does
    // not have to read `current` and subscribe separately and risk missing a
    // change between the two.
    //
    // Written as `Stream.multi` rather than an `async*` generator, and the
    // difference is the whole point of the promise. A generator does not
    // subscribe to what it delegates to until its first yielded value has been
    // consumed, so a change arriving in that window is dropped by a broadcast
    // source — reintroducing exactly the gap this method exists to close. Here
    // the subscription is made first and the seed value is queued behind it.
    return Stream<NetworkCondition>.multi((controller) {
      final subscription = _changes.stream.listen(
        controller.add,
        onDone: controller.close,
      );
      controller
        ..onCancel = subscription.cancel
        ..add(_current);
    });
  }

  /// Reads the condition once and starts following changes.
  ///
  /// Safe to call more than once; the second call is a no-op.
  Future<void> start() async {
    if (_subscription != null) {
      return;
    }
    _current = await _read();
    _subscription = _platform.onConnectivityChanged.listen(
      (results) => _publish(toNetworkCondition(results)),
      // A stream that errors is a subsystem that stopped answering, which is
      // indistinguishable from being offline as far as the product is
      // concerned.
      onError: (Object _) => _publish(NetworkCondition.offline),
    );
  }

  /// Stops following changes and closes [changes].
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _changes.close();
  }

  void _publish(NetworkCondition condition) {
    // Deduplicated on the mapped value, not the raw one. The plugin emits for
    // every transport change — gaining a VPN over the same wifi, for example —
    // and a listener woken for those would be woken for nothing.
    if (condition == _current) {
      return;
    }
    _current = condition;
    _changes.add(condition);
  }

  Future<NetworkCondition> _read() async {
    try {
      return toNetworkCondition(await _platform.checkConnectivity());
    } on Object {
      return NetworkCondition.offline;
    }
  }
}
