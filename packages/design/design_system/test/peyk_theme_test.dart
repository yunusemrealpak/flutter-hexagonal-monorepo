@Tags(['widget'])
library;

import 'package:design_system/design_system.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeykTheme.themeData', () {
    test('installs the extension the components read', () {
      final theme = PeykTheme.themeData(PeykPalette.dark);

      expect(theme.extension<PeykTheme>()?.palette, same(PeykPalette.dark));
    });

    // The reason the two halves live in one class. An app makes one decision —
    // which palette — and both the Material surface and the Peyk components
    // follow it. A ThemeData built separately from the extension could put a
    // light ColorScheme behind dark components and nothing would fail.
    test('agrees with the palette it was built from', () {
      final theme = PeykTheme.themeData(PeykPalette.dark);

      expect(theme.brightness, PeykPalette.dark.brightness);
      expect(theme.colorScheme.surface, PeykPalette.dark.surface);
      expect(theme.scaffoldBackgroundColor, PeykPalette.dark.surface);
    });
  });

  group('PeykTheme.lerp', () {
    const light = PeykTheme(palette: PeykPalette.light);
    const dark = PeykTheme(palette: PeykPalette.dark);

    test('switches at the halfway point instead of interpolating', () {
      expect(light.lerp(dark, 0).palette, same(PeykPalette.light));
      expect(light.lerp(dark, 0.49).palette, same(PeykPalette.light));
      expect(light.lerp(dark, 0.5).palette, same(PeykPalette.dark));
      expect(light.lerp(dark, 1).palette, same(PeykPalette.dark));
    });

    test('never produces a palette that was not checked for contrast', () {
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        final palette = light.lerp(dark, t).palette;
        expect(
          palette,
          anyOf(same(PeykPalette.light), same(PeykPalette.dark)),
          reason: 'lerp at $t produced an intermediate palette',
        );
      }
    });
  });

  // The totality that used to live in design_tokens, following the enum here.
  group('PeykPalette.colorsFor', () {
    test('is total over PeykIntent in both palettes', () {
      for (final palette in [PeykPalette.light, PeykPalette.dark]) {
        for (final intent in PeykIntent.values) {
          expect(palette.colorsFor(intent), isNotNull);
        }
      }
    });

    test('returns the triple named after the intent', () {
      const palette = PeykPalette.light;

      expect(palette.colorsFor(PeykIntent.neutral), same(palette.neutral));
      expect(palette.colorsFor(PeykIntent.info), same(palette.info));
      expect(palette.colorsFor(PeykIntent.success), same(palette.success));
      expect(palette.colorsFor(PeykIntent.warning), same(palette.warning));
      expect(palette.colorsFor(PeykIntent.danger), same(palette.danger));
    });
  });

  group('PeykGap', () {
    // The reason the sizes are named for what they mean: two callers reaching
    // for "the gap between groups" get the same number without measuring it.
    test('every size maps to a step of the scale', () {
      for (final size in PeykGapSize.values) {
        expect(PeykGap.pixels(size), greaterThan(0));
      }
    });

    test('the steps are ordered the way their names are', () {
      final extents = PeykGapSize.values.map(PeykGap.pixels).toList();

      expect(extents, orderedEquals(List.of(extents)..sort()));
    });
  });

  testWidgets('PeykTheme.of finds the palette an app installed', (
    tester,
  ) async {
    late PeykPalette seen;

    await tester.pumpWidget(
      PeykTheme.wrap(
        palette: PeykPalette.dark,
        child: Builder(
          builder: (context) {
            seen = PeykTheme.of(context).palette;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, same(PeykPalette.dark));
  });
}
