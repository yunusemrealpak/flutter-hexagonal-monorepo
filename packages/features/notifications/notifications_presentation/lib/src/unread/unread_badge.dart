import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'unread_bloc.dart';
import 'unread_state.dart';

/// How many alerts are waiting, drawn wherever an app wants it.
///
/// A separate widget from the inbox screen, and it exists because the count is
/// drawn on screens that have nothing else to do with notifications — a route
/// list, a shipment detail. Exporting the badge rather than the count is what
/// keeps those screens from having to hold a `NotificationsFacade` of their
/// own.
///
/// It reads [UnreadBloc] from the tree, so an app mounts one provider high
/// enough for every screen that draws a badge and none of them holds anything.
///
/// The zero case and the spoken label both belong to `PeykBadge`: "3 unread"
/// is a sentence about a component, and Turkish and English disagree about
/// what happens to the noun after the number. This widget's job is the
/// subscription, not the grammar.
final class UnreadBadge extends StatelessWidget {
  /// Creates the badge.
  ///
  /// Whoever mounts it puts an [UnreadBloc] above it with `BlocProvider`.
  const UnreadBadge({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<UnreadBloc, UnreadState>(
    builder: (context, state) => switch (state) {
      // Nothing at all until a count has arrived. Drawing zero would be a
      // claim that nothing is waiting, made before anything is known.
      UnreadUnknown() => const SizedBox.shrink(),
      UnreadCount(:final value) => PeykBadge(count: value),
    },
  );
}
