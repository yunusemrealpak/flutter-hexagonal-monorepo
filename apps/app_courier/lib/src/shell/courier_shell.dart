import 'package:design_system/design_system.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_presentation/sync_presentation.dart';

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
///
/// **It is also where the queue badge hangs, and the position is the
/// argument.** `SyncStatusBadge` says what the outbox is doing, and what it
/// says is true of the device rather than of whichever tab is in force — so it
/// belongs to the one widget that outlives a tab switch. Per screen it would
/// be four copies subscribing separately and disagreeing for a frame; in
/// `PeykScreen.actions` it would be a decision every feature has to remember
/// to make, and `delivery_presentation` would need a `sync_presentation`
/// dependency the constitution does not give it.
///
/// It is drawn on every tab and in every state, including `SyncIdle`. The
/// badge's own reasoning is why: five statuses are five different sentences,
/// and a courier who cannot tell *everything is sent* from *the badge is
/// broken* is a courier who restarts an app that is working.
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
      // Both in `bottomNavigationBar` rather than a `Column` in the body, so
      // that the strip travels with the bar: `Scaffold` is what keeps this
      // slot clear of the system inset, and a strip in the body would sit
      // above the bar on a phone and under the home indicator on a tablet.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SyncStrip(),
          PeykNavigationBar(
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
        ],
      ),
    );
  }
}

/// The line the queue badge sits on, above the bar.
///
/// Right-aligned and one chip tall. It carries no title, because the badge
/// already says what it is about and a label beside it would be a second
/// sentence competing with the four under it.
final class _SyncStrip extends StatelessWidget {
  const _SyncStrip();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: PeykSpacing.lg,
      vertical: PeykSpacing.xs,
    ),
    child: Align(
      alignment: Alignment.centerRight,
      child: SyncStatusBadge(),
    ),
  );
}
