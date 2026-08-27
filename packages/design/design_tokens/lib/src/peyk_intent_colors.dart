import 'dart:ui';

import 'peyk_intent.dart';

/// The three colours one [PeykIntent] is drawn from on one palette.
///
/// A triple rather than a single colour, because every place an intent is used
/// needs all three at once: a chip fills with [background], writes in
/// [foreground] and is separated from the surface behind it by [border]. Three
/// separate token lookups would let a component pick a foreground from one
/// intent and a background from another, which is exactly the contrast bug
/// nobody sees until it ships.
final class PeykIntentColors {
  /// Creates the triple.
  const PeykIntentColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  /// What is written or drawn on top.
  final Color foreground;

  /// The wash behind it.
  final Color background;

  /// The edge between the wash and the surface it sits on.
  final Color border;
}
