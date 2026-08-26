import 'package:flutter/widgets.dart';

import 'inbox_controller.dart';

/// How many alerts are waiting, drawn wherever an app wants it.
///
/// A separate widget from the inbox screen, and it exists because the count is
/// drawn on screens that have nothing else to do with notifications — a route
/// list, a shipment detail. Exporting the badge rather than the count is what
/// keeps those screens from having to hold a `NotificationsFacade` of their
/// own.
///
/// It shows nothing at all when the count is zero. A badge reading "0" is a
/// badge that has to be looked at to be dismissed.
final class UnreadBadge extends StatelessWidget {
  /// Creates the badge over [controller].
  const UnreadBadge({required this.controller, super.key});

  /// What drives it.
  final InboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => controller.unread == 0
        ? const SizedBox.shrink()
        : Semantics(
            label: 'inbox.unread',
            child: Text('${controller.unread}'),
          ),
  );
}
