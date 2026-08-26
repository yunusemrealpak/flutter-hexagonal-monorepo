import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:notifications_api/notifications_api.dart';

import 'inbox_controller.dart';
import 'inbox_state.dart';

/// Where a courier reads what the operation has told them.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7.
final class InboxScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const InboxScreen({required this.controller, super.key});

  /// What drives it.
  final InboxController controller;

  @override
  State<InboxScreen> createState() => _InboxScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `NotificationsFailure`, which is the point of it being
  /// sealed: the day notifications learns a new way to fail, this stops
  /// compiling instead of showing a courier the wrong sentence.
  static String describe(NotificationsFailure failure) => switch (failure) {
    InboxUnavailable() => 'Your alerts could not be read.',
    NotificationMissing() => 'That alert is no longer here.',
    AlertsRefused() => 'Alerts are off. Turn them on to be told about work.',
    AlertsBlocked() => 'Alerts are blocked in the system settings.',
    AlertsUnreachable() => 'This device could not be registered for alerts.',
    MalformedNotification() => 'An alert could not be read.',
  };
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      InboxIdle() || InboxLoading() => const Text('inbox.loading'),
      // An empty inbox is its own line rather than an empty list, because a
      // screen with nothing on it reads as a screen that failed to load.
      InboxReady(:final entries) when entries.isEmpty => const Text(
        'inbox.empty',
      ),
      InboxReady(:final entries) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries)
            _Alert(entry: entry, controller: widget.controller),
        ],
      ),
      InboxFailed(:final failure) => Text(InboxScreen.describe(failure)),
    },
  );
}

/// One alert in the list.
///
/// The label is a localisation key with its arguments appended, not a
/// sentence: the strings belong to the app's localisation, which arrives in
/// phase 7. Writing Turkish here would mean deleting it then.
class _Alert extends StatelessWidget {
  const _Alert({required this.entry, required this.controller});

  final InboxEntry entry;
  final InboxController controller;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: entry.isUnread ? () => controller.markRead(entry.id) : null,
    child: Semantics(
      button: entry.isUnread,
      child: Text(
        entry.arguments.isEmpty
            ? entry.subject
            : '${entry.subject} ${entry.arguments}',
      ),
    ),
  );
}
