import 'package:flutter/material.dart';

import 'peyk_icon.dart';
import 'peyk_navigation_destination.dart';
import 'peyk_theme.dart';

/// The bar along the bottom of a shell.
///
/// It draws [destinations] in the order given, marks [currentIndex] as the one
/// in force, and reports every tap through [onSelected] — **including a tap on
/// the destination already selected**. That repeat is not noise: tapping the
/// tab you are already on is how somebody three screens deep gets back to the
/// top of it, and a bar that swallowed it would make that impossible to build
/// above. What the repeat means is the app's decision, as it is for every
/// other tap.
///
/// **It takes data and returns an index.** No route name, no navigator, no
/// router library. A bar that navigated would have to name destinations, which
/// is the design §2.4 rejects — one level down from where that section argues
/// it, and for the same reason: the set of tabs belongs to the audience an app
/// serves, not to a component every app shares.
///
/// Labels are drawn under every icon rather than under the selected one only.
/// Roughly one courier in twelve cannot separate two of the palette's tones,
/// the icons are 24 logical pixels of grey either way, and the alternative is
/// a bar you have to tap to read.
final class PeykNavigationBar extends StatelessWidget {
  /// Creates a bar over [destinations].
  const PeykNavigationBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  /// Where this bar can send somebody, left to right.
  final List<PeykNavigationDestination> destinations;

  /// Which of them is in force.
  final int currentIndex;

  /// What a tap reports. Fires for the current destination too.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;

    return NavigationBar(
      backgroundColor: palette.surface,
      indicatorColor: palette.primaryMuted,
      surfaceTintColor: palette.surface,
      selectedIndex: currentIndex,
      // Material would otherwise report only a *change* of index, and the
      // re-tap this component promises to forward is precisely the case where
      // the index does not change.
      onDestinationSelected: onSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon.glyph, color: palette.onSurfaceMuted),
            selectedIcon: Icon(destination.icon.glyph, color: palette.primary),
            label: destination.label,
          ),
      ],
    );
  }
}
