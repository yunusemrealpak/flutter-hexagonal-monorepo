import 'dart:async';

import 'package:core_ports/core_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

/// Decides when the outbox is worth draining.
///
/// `SyncFacade.drain` names its caller in its own documentation — *"whatever
/// decides that now is a good moment: a connectivity change, a foreground
/// transition, a timer in the composition root"* — and until this class
/// existed, nothing did. Writes went into the queue and stayed there until
/// somebody opened the review screen and pressed retry.
///
/// **It is in the app because the decision belongs to no feature.** `sync`
/// knows what is due; it does not know what else the device is doing. A use
/// case that subscribed to connectivity would be a use case that never
/// returns, and `DrainOutbox` is one that runs once. This is the composition
/// root owning a policy, for the same reason it owns the container.
///
/// **Nothing it does is required for correctness.** A drain that never
/// happens loses no work: the outbox is durable and the review screen can
/// still start one by hand. What this buys is that a courier who walks back
/// into signal does not have to know that.
final class SyncOrchestrator {
  /// Creates an orchestrator over [sync], watching [network].
  SyncOrchestrator({
    required SyncFacade sync,
    required NetworkStatus network,
    required Logger logger,
  }) : _sync = sync,
       _network = network,
       _logger = logger;
  // The parameters are named without the leading underscore so that a call
  // site reads `sync:` rather than `_sync:`; `prefer_initializing_formals`
  // wants the opposite and is worse to read at every construction.
  // ignore_for_file: prefer_initializing_formals

  final SyncFacade _sync;
  final NetworkStatus _network;
  final Logger _logger;

  StreamSubscription<NetworkCondition>? _conditions;
  AppLifecycleListener? _lifecycle;

  /// Whether a drain is already running.
  ///
  /// Two drains at once would attempt the same entries twice. The queue is
  /// idempotent on the server — the entry id is what it de-duplicates on —
  /// but sending everything twice on a metered link is a courier's data
  /// allowance.
  bool _draining = false;

  /// The last condition seen, so that a repeated event is not a transition.
  ///
  /// `NetworkStatus.changes` emits the current value on subscription and may
  /// emit the same condition again; only a move *into* a usable connection is
  /// a reason to try.
  NetworkCondition? _last;

  /// Starts watching, and drains once if there is already a connection.
  ///
  /// The initial drain is what covers the case a courier cares about most:
  /// the app was killed in a basement and reopened on the street.
  void start() {
    _conditions ??= _network.changes().listen(_onCondition);
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(drainNow()));
  }

  /// Attempts every entry that is due, unless one attempt is already running.
  ///
  /// Public so that a foreground transition, a pull-to-refresh or a test can
  /// ask for one without going through the network stream.
  Future<void> drainNow() async {
    if (_draining || _network.current == NetworkCondition.offline) return;
    _draining = true;
    try {
      final drained = await _sync.drain();
      drained.fold(
        (status) =>
            _logger.debug('sync drained', context: {'status': '$status'}),
        // A failed drain is not an error a person can act on: the entries are
        // still queued and the next connection tries again. It is logged
        // rather than surfaced, because a courier who is told about it has
        // nothing to do about it.
        (failure) =>
            _logger.warning('sync drain refused', context: {'why': '$failure'}),
      );
    } finally {
      _draining = false;
    }
  }

  /// Stops watching.
  Future<void> dispose() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    await _conditions?.cancel();
    _conditions = null;
  }

  void _onCondition(NetworkCondition condition) {
    final previous = _last;
    _last = condition;
    if (condition == NetworkCondition.offline) return;
    // A repeat of a usable condition is not a transition. Wifi that reports
    // itself twice is not a courier walking out of a basement.
    if (previous != null && previous != NetworkCondition.offline) return;
    unawaited(drainNow());
  }
}
