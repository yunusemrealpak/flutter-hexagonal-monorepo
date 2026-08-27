import 'dart:ui';

import 'peyk_intent.dart';
import 'peyk_intent_colors.dart';

/// One complete set of colours, named by role rather than by hue.
///
/// Two instances exist — [light] and [dark] — and they carry the same field
/// names, which is what lets every component be written once. A component that
/// asked "is this dark?" and picked a colour would be a component that has to
/// be reviewed twice.
///
/// The palette is a plain object rather than a `ThemeExtension`, and that is
/// the boundary this package draws: a token is a value, a theme is a Flutter
/// mechanism for carrying values down a widget tree. `design_system` owns the
/// second one.
final class PeykPalette {
  /// Creates a palette. Both product palettes are declared below; the
  /// constructor is public so that a test or a preview can build a third.
  const PeykPalette({
    required this.brightness,
    required this.surface,
    required this.surfaceMuted,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.primaryMuted,
    required this.focus,
    required this.neutral,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Whether this palette is meant for a light or a dark device.
  final Brightness brightness;

  /// The colour a screen is drawn on.
  final Color surface;

  /// A quieter surface, for something set into the screen rather than on it.
  final Color surfaceMuted;

  /// Text and icons on [surface].
  final Color onSurface;

  /// Secondary text on [surface]: a timestamp, a hint, a disabled label.
  final Color onSurfaceMuted;

  /// The line between two things that are not otherwise separated.
  final Color outline;

  /// The brand colour, used for the one action a screen wants most.
  final Color primary;

  /// Text and icons drawn on [primary].
  final Color onPrimary;

  /// A wash of [primary], for a selected row or a quiet emphasis.
  final Color primaryMuted;

  /// The ring drawn around whatever the keyboard is on.
  ///
  /// Its own slot rather than [primary], because a focus ring has to stay
  /// visible on top of a primary-coloured control.
  final Color focus;

  /// Colours for [PeykIntent.neutral].
  final PeykIntentColors neutral;

  /// Colours for [PeykIntent.info].
  final PeykIntentColors info;

  /// Colours for [PeykIntent.success].
  final PeykIntentColors success;

  /// Colours for [PeykIntent.warning].
  final PeykIntentColors warning;

  /// Colours for [PeykIntent.danger].
  final PeykIntentColors danger;

  /// The colours for [intent].
  ///
  /// A total function over the enum rather than a map, so that adding an
  /// intent stops this compiling instead of returning null at one call site
  /// somebody has to find.
  PeykIntentColors of(PeykIntent intent) => switch (intent) {
    PeykIntent.neutral => neutral,
    PeykIntent.info => info,
    PeykIntent.success => success,
    PeykIntent.warning => warning,
    PeykIntent.danger => danger,
  };

  /// The palette for a light device.
  static const PeykPalette light = PeykPalette(
    brightness: Brightness.light,
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F6F8),
    onSurface: Color(0xFF10151B),
    onSurfaceMuted: Color(0xFF5B6672),
    outline: Color(0xFFD8DEE5),
    primary: Color(0xFF1B4DE4),
    onPrimary: Color(0xFFFFFFFF),
    primaryMuted: Color(0xFFE8EDFD),
    focus: Color(0xFF0B2E8F),
    neutral: PeykIntentColors(
      foreground: Color(0xFF3C4653),
      background: Color(0xFFEEF1F4),
      border: Color(0xFFD8DEE5),
    ),
    info: PeykIntentColors(
      foreground: Color(0xFF13497A),
      background: Color(0xFFE4F0FB),
      border: Color(0xFFBBD8F2),
    ),
    success: PeykIntentColors(
      foreground: Color(0xFF17593A),
      background: Color(0xFFE3F4EA),
      border: Color(0xFFB6E0C7),
    ),
    warning: PeykIntentColors(
      foreground: Color(0xFF7A4B0B),
      background: Color(0xFFFDF0DC),
      border: Color(0xFFF3D19A),
    ),
    danger: PeykIntentColors(
      foreground: Color(0xFF8A1F1F),
      background: Color(0xFFFCE8E8),
      border: Color(0xFFF2BFBF),
    ),
  );

  /// The palette for a dark device.
  ///
  /// Not the light one inverted. A courier reads this screen in a van at six
  /// in the morning and at eleven at night, so the dark surfaces are dark
  /// enough to stop being a lamp and the intent washes are dim enough that a
  /// row of chips does not glow.
  static const PeykPalette dark = PeykPalette(
    brightness: Brightness.dark,
    surface: Color(0xFF0E1116),
    surfaceMuted: Color(0xFF161B22),
    onSurface: Color(0xFFE7ECF2),
    onSurfaceMuted: Color(0xFF9BA7B4),
    outline: Color(0xFF2A323C),
    primary: Color(0xFF6E9BFF),
    onPrimary: Color(0xFF06122B),
    primaryMuted: Color(0xFF17233F),
    focus: Color(0xFFA8C4FF),
    neutral: PeykIntentColors(
      foreground: Color(0xFFC3CCD6),
      background: Color(0xFF1B222B),
      border: Color(0xFF2A323C),
    ),
    info: PeykIntentColors(
      foreground: Color(0xFF8CC2F0),
      background: Color(0xFF11212F),
      border: Color(0xFF1E3A50),
    ),
    success: PeykIntentColors(
      foreground: Color(0xFF7ED6A4),
      background: Color(0xFF0F2119),
      border: Color(0xFF1D3B2B),
    ),
    warning: PeykIntentColors(
      foreground: Color(0xFFF0C070),
      background: Color(0xFF241B0D),
      border: Color(0xFF43331A),
    ),
    danger: PeykIntentColors(
      foreground: Color(0xFFF09090),
      background: Color(0xFF2A1315),
      border: Color(0xFF4A2124),
    ),
  );
}
