import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

import 'key_echo_catalogue.dart';
import 'l10n/peyk_system_localizations.dart';
import 'peyk_strings.dart';
import 'peyk_type_style.dart';
import 'string_catalogue.dart';

/// Carries the palette in force down the widget tree, and builds the
/// `ThemeData` an app hands to `MaterialApp`.
///
/// The two halves are here for one reason: an app should make one decision —
/// which palette — and get a Material theme and the Peyk components agreeing
/// about it. An app that built its own `ThemeData` and separately installed a
/// palette could put a light `ColorScheme` behind dark components, and nothing
/// would fail until somebody looked at it.
final class PeykTheme extends ThemeExtension<PeykTheme> {
  /// Carries [palette].
  const PeykTheme({required this.palette});

  /// The theme in force at [context].
  ///
  /// A factory rather than the static method Flutter's own `Theme.of` is,
  /// because it returns an instance of this class and
  /// `prefer_constructors_over_static_methods` is part of the workspace
  /// baseline. Call sites read identically either way.
  ///
  /// Asserts rather than throwing, and falls back to the light palette in
  /// release. A component drawn outside a Peyk theme is a wiring mistake worth
  /// failing a test over; it is not worth a red screen in a courier's hand
  /// halfway through a delivery.
  factory PeykTheme.of(BuildContext context) {
    final theme = Theme.of(context).extension<PeykTheme>();
    assert(
      theme != null,
      'No PeykTheme in this tree. An app installs one by building its '
      'ThemeData with PeykTheme.themeData(); a widget test wraps the subject '
      'in PeykTheme.wrap().',
    );
    return theme ?? const PeykTheme(palette: PeykPalette.light);
  }

  /// The colours every component reads.
  final PeykPalette palette;

  /// The Material theme for [palette], with this extension installed in it.
  static ThemeData themeData(PeykPalette palette) {
    final scheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryMuted,
      onPrimaryContainer: palette.onSurface,
      secondary: palette.info.foreground,
      onSecondary: palette.surface,
      error: palette.danger.foreground,
      onError: palette.danger.background,
      surface: palette.surface,
      onSurface: palette.onSurface,
      surfaceContainerHighest: palette.surfaceMuted,
      onSurfaceVariant: palette.onSurfaceMuted,
      outline: palette.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.surface,
      textTheme: _textTheme(palette),
      extensions: [PeykTheme(palette: palette)],
    );
  }

  /// Wraps [child] in a minimal tree carrying [palette].
  ///
  /// What a widget test uses. It exists here rather than in a test helper so
  /// that the fourteen presentation packages testing against these components
  /// do not each invent their own wrapper, and so that a component which grows
  /// a new ambient requirement is fixed in one place instead of fourteen.
  ///
  /// The default catalogue is [KeyEchoCatalogue], which is what makes a widget
  /// test assert `find.text('settings.theme.dark')` — a claim about which
  /// string the screen asked for — instead of asserting a translation that
  /// changes the next time somebody improves the wording.
  static Widget wrap({
    required Widget child,
    PeykPalette palette = PeykPalette.light,
    Locale locale = const Locale('en'),
    StringCatalogue catalogue = const KeyEchoCatalogue(),
  }) => MaterialApp(
    theme: themeData(palette),
    locale: locale,
    localizationsDelegates: PeykSystemLocalizations.localizationsDelegates,
    supportedLocales: PeykSystemLocalizations.supportedLocales,
    // The Material ancestor is part of what "the tree these components need"
    // means. PeykScreen brings its own Scaffold, but a component tested on its
    // own — a field, a row, a chip — has no screen above it, and TextField
    // asserts on the absence. Putting it here is the point of the helper: one
    // place, rather than fourteen packages each discovering the requirement
    // separately.
    home: Material(
      child: PeykStrings(catalogue: catalogue, child: child),
    ),
  );

  @override
  PeykTheme copyWith({PeykPalette? palette}) =>
      PeykTheme(palette: palette ?? this.palette);

  /// Switches palettes at the halfway point rather than interpolating.
  ///
  /// Deliberate. Interpolating two palettes produces colours that exist for
  /// 220 milliseconds and were never held to the contrast bar the two ends
  /// were — every intermediate frame of a light-to-dark transition is a
  /// palette nobody checked. A hard switch is one unchecked frame instead of
  /// thirty, and in practice nobody sees it.
  @override
  PeykTheme lerp(covariant PeykTheme? other, double t) =>
      t < 0.5 || other == null ? this : other;

  static TextTheme _textTheme(PeykPalette palette) {
    final onSurface = palette.onSurface;
    final muted = palette.onSurfaceMuted;
    return TextTheme(
      headlineMedium: PeykTypeScale.display.toTextStyle(onSurface),
      titleLarge: PeykTypeScale.title.toTextStyle(onSurface),
      bodyLarge: PeykTypeScale.body.toTextStyle(onSurface),
      bodyMedium: PeykTypeScale.body.toTextStyle(onSurface),
      labelLarge: PeykTypeScale.label.toTextStyle(onSurface),
      bodySmall: PeykTypeScale.caption.toTextStyle(muted),
    );
  }
}
