import 'package:design_system/design_system.dart';
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
/// The zero case and the spoken label both belong to `PeykBadge`: "3 unread"
/// is a sentence about a component, and Turkish and English disagree about
/// what happens to the noun after the number. This widget's job is the
/// subscription, not the grammar.
final class UnreadBadge extends StatelessWidget {
  /// Creates the badge over [controller].
  const UnreadBadge({required this.controller, super.key});

  /// What drives it.
  final InboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PeykBadge(count: controller.unread),
  );
}
