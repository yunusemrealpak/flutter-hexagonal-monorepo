import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'courier_tabs.dart';

/// The frame a signed-in courier sees: whichever tab is in force, with the bar
/// under it.
///
/// This widget is the third piece of §2.4's split, and the one that shows why
/// the other two are shaped as they are. `PeykNavigationBar` reports an index
/// and knows no route; `courierTabs` names routes and draws nothing; this
/// file, in the app, is the only place where an index becomes a destination.
///
/// **The re-tap is why the bar forwards a tap on the current destination.**
/// `goBranch(initialLocation: true)` resets that branch to its root, which is
/// what a courier expects from tapping the tab they are already on. Material's
/// bar reports it; a component that filtered it would have made this behaviour
/// unbuildable from outside.
final class CourierShell extends StatelessWidget {
  /// Draws [shell] with a bar for [tabs].
  const CourierShell({required this.tabs, required this.shell, super.key});

  /// The tabs, in the order the bar shows them.
  final List<CourierTab> tabs;

  /// go_router's branch container, which owns the per-tab navigators.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // Resolved here rather than in the bar, because a component is given
    // sentences and never keys — and because this is the layer that has an
    // app's catalogue in scope.
    final strings = PeykStrings.of(context);

    return Scaffold(
      body: shell,
      bottomNavigationBar: PeykNavigationBar(
        destinations: [
          for (final tab in tabs)
            PeykNavigationDestination(
              label: strings.resolve(tab.label),
              icon: tab.icon,
            ),
        ],
        currentIndex: shell.currentIndex,
        onSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
