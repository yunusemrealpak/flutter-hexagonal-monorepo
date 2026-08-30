import 'peyk_icon.dart';
import 'peyk_navigation_bar.dart';

/// One place a [PeykNavigationBar] can send somebody.
///
/// Data, not a route. This type carries a word and a picture and knows nothing
/// about where tapping it leads — the bar reports an index and the app decides
/// what that index means, which is §2.4 of docs/DEPENDENCY_RULES.md at the
/// level of a component: a widget reports an outcome, the app supplies the
/// destination.
///
/// A destination a bar could navigate itself would need a route name, and a
/// route name in `design_system` would be a design system that knows a courier
/// has a manifest.
final class PeykNavigationDestination {
  /// Describes a destination shown as [label] under [icon].
  const PeykNavigationDestination({required this.label, required this.icon});

  /// The word under the picture. Already resolved.
  final String label;

  /// The picture.
  final PeykIcon icon;
}
