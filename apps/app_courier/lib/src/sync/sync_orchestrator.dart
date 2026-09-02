import 'dart:async';

import 'package:background_tasks/background_tasks.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:sync_api/sync_api.dart';

import 'background_drain.dart';

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
///
/// **It also asks the operating system to try while this app is not running.**
/// Every other trigger here needs the app to be alive, so a courier who force
/// quits in a basement sent nothing until they reopened it. The scheduler is
/// optional because whether a device can be woken is an app's answer, the same
/// way an alert channel is: `app_dispatcher` passes none, and its outbox is in
/// memory anyway.
final class SyncOrchestrator {
  /// Creates an orchestrator over [sync], watching [network].
  SyncOrchestrator({
    required SyncFacade sync,
    required NetworkStatus network,
    required Logger logger,
    BackgroundScheduler? scheduler,
  }) : _sync = sync,
       _network = network,
       _logger = logger,
       _scheduler = scheduler;
  // The parameters are named without the leading underscore so that a call
  // site reads `sync:` rather than `_sync:`; `prefer_initializing_formals`
  // wants the opposite and is worse to read at every construction.
  // ignore_for_file: prefer_initializing_formals

  final SyncFacade _sync;
  final NetworkStatus _network;
  final Logger _logger;
  final BackgroundScheduler? _scheduler;

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
    unawaited(_scheduleBackgroundDrain());
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

  /// Asks the operating system to consider a drain while this app is not.
  ///
  /// On every start, and the contract is what makes that safe: scheduling a
  /// name that is already scheduled replaces it. An app that only did this
  /// once would never move a device onto a new interval.
  ///
  /// A refusal is logged and nothing else. Background execution is the one
  /// trigger of the four that a person can switch off in the system settings,
  /// and an app that treated that as an error would be reporting a preference
  /// as a fault — the queue is durable and every other trigger still works.
  Future<void> _scheduleBackgroundDrain() async {
    final scheduler = _scheduler;
    if (scheduler == null) return;

    final scheduled = await scheduler.schedulePeriodic(
      name: drainTaskName,
      interval: drainInterval,
      // Waking to find no connection would spend a courier's battery on a
      // drain that returns immediately. The drain checks `NetworkStatus`
      // anyway; this stops the wake-up rather than the work.
      constraints: const TaskConstraints(networkRequired: true),
    );
    if (scheduled case Failed(:final failure)) {
      _logger.info(
        'no background drain on this device',
        context: {'why': '$failure'},
      );
    }
  }

  /// Stops watching.
  ///
  /// It deliberately does not cancel the background schedule. Disposing this
  /// object means the app is going away, which is precisely when the
  /// scheduled task is the only thing left that can send anything.
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
