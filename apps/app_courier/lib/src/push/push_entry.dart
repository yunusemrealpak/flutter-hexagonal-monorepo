import 'dart:async';

import 'package:core_ports/core_ports.dart';
import 'package:push_messaging/push_messaging.dart';

import '../router/courier_flow.dart';
import 'courier_entry_points.dart';

/// Opens the app where a pressed notification says it should open.
///
/// The same shape as `SyncOrchestrator`, and it exists for the same kind of
/// reason: `PushMessagingClient.openings()` describes an intention nobody was
/// acting on, and a courier who pressed a dispatcher's message landed on
/// whatever screen the app happened to start at.
///
/// **This is the case §2.4 of the dependency rules reserves for a URL.** A
/// screen reports an outcome and the app decides where that leads — but a
/// notification tap is not a screen and cannot invoke a callback. Arrival goes
/// through the router, which means it goes through the guard: a courier who
/// presses a notification while signed out is sent to sign-in carrying the
/// destination in `?from=`, and arrives at it once there is a session. That
/// round trip is what makes entry a URL rather than a call.
///
/// **It navigates by name, not by widget.** [_go] is supplied by the
/// composition root and is one line — `router.goNamed(step.route, ...)` — for
/// the same reason `CourierFlow`'s steps are: the mapping stays a value, and
/// this class stays testable without a widget tree.
final class PushEntry {
  /// Watches [push] and opens what [entries] says a message leads to.
  PushEntry({
    required PushMessagingClient push,
    required void Function(FlowStep step) go,
    required Logger logger,
    CourierEntryPoints entries = const CourierEntryPoints(),
  }) : _push = push,
       _go = go,
       _logger = logger,
       _entries = entries;
  // Named without the leading underscore so that a call site reads `push:`
  // rather than `_push:`; `prefer_initializing_formals` wants the opposite and
  // is worse to read at every construction.
  // ignore_for_file: prefer_initializing_formals

  final PushMessagingClient _push;
  final void Function(FlowStep step) _go;
  final Logger _logger;
  final CourierEntryPoints _entries;

  StreamSubscription<PushMessage>? _openings;

  /// Opens the launch notification, if there was one, and watches for presses.
  ///
  /// The order matters and the asymmetry is the platform's: a press that
  /// launched the app from nothing is waiting to be read, while a press that
  /// brought it back from the background arrives on a stream. Reading the
  /// first is a one-shot — the provider hands it over once — so a second call
  /// to this method opens nothing, which is what a resume should do.
  Future<void> start() async {
    _openings ??= _push.openings().listen(_open);
    final launch = await _push.launchMessage();
    if (launch != null) {
      _open(launch);
    }
  }

  /// Stops watching.
  Future<void> dispose() async {
    await _openings?.cancel();
    _openings = null;
  }

  void _open(PushMessage message) {
    final step = _entries.forMessage(message);
    if (step == null) {
      // Normal traffic rather than a fault: a kind this version does not know,
      // or a message about a thread that names no thread. Logged because a
      // server that starts sending either is worth noticing in the field, and
      // ignored because the alternative is opening a screen at random.
      _logger.debug(
        'push opened nothing',
        context: {'kind': message.kind.name, 'id': message.id},
      );
      return;
    }
    _logger.debug(
      'push opening a destination',
      context: {'kind': message.kind.name, 'route': step.route},
    );
    _go(step);
  }
}
