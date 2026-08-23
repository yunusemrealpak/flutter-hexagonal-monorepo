import 'dart:async';

import 'package:core_ports/core_ports.dart';

/// A [NetworkStatus] a test can move between conditions.
///
/// Offline-first behaviour is the hardest thing in this product to test
/// against reality and the easiest to test against this: going offline is a
/// method call, and the transition back is another.
final class FakeNetworkStatus implements NetworkStatus {
  /// Starts in [initial], unmetered by default.
  FakeNetworkStatus([NetworkCondition initial = NetworkCondition.unmetered])
    : _current = initial;

  final StreamController<NetworkCondition> _controller =
      StreamController<NetworkCondition>.broadcast();
  NetworkCondition _current;

  @override
  NetworkCondition get current => _current;

  @override
  Stream<NetworkCondition> changes() =>
      // Not `async*`. An async generator does not subscribe to the underlying
      // stream until after its first yield has been delivered, so anything
      // emitted in that gap is dropped — a test that subscribes and then
      // immediately drives a transition would silently miss it. Stream.multi
      // runs its callback synchronously on listen, so the seed value and the
      // subscription are established before control returns to the caller.
      Stream<NetworkCondition>.multi((controller) {
        controller.add(_current);
        final subscription = _controller.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

  /// Moves to [condition] and notifies listeners.
  ///
  /// Setting the condition it is already in emits nothing, matching what a
  /// real connectivity adapter does — otherwise a test would see phantom
  /// transitions no device would produce.
  void set(NetworkCondition condition) {
    if (condition == _current) {
      return;
    }
    _current = condition;
    _controller.add(condition);
  }

  /// Releases the change stream. Call from `addTearDown`.
  Future<void> dispose() => _controller.close();
}
