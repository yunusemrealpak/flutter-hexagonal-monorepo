import 'package:design_tokens/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contrast.dart';

void main() {
  group('PeykPalette.of', () {
    test('is total over PeykIntent in both palettes', () {
      for (final palette in [PeykPalette.light, PeykPalette.dark]) {
        for (final intent in PeykIntent.values) {
          expect(palette.of(intent), isNotNull);
        }
      }
    });

    test('returns the triple named after the intent', () {
      const palette = PeykPalette.light;

      expect(palette.of(PeykIntent.neutral), same(palette.neutral));
      expect(palette.of(PeykIntent.info), same(palette.info));
      expect(palette.of(PeykIntent.success), same(palette.success));
      expect(palette.of(PeykIntent.warning), same(palette.warning));
      expect(palette.of(PeykIntent.danger), same(palette.danger));
    });
  });

  // The test that makes this package worth having. A palette is a set of
  // numbers somebody picked, and the only property of those numbers that
  // cannot be argued about is whether a person can read the result. Every pair
  // that ends up as text on a background is checked against WCAG 2.1 AA here,
  // so a colour changed by eye fails in CI rather than in the field — where
  // the field is a phone in direct sunlight.
  group('contrast', () {
    for (final (name, palette) in [
      ('light', PeykPalette.light),
      ('dark', PeykPalette.dark),
    ]) {
      group(name, () {
        test('body text on the surface reaches AAA', () {
          expect(
            contrastRatio(palette.onSurface, palette.surface),
            greaterThanOrEqualTo(7),
          );
        });

        test('muted text on both surfaces reaches AA', () {
          expect(
            contrastRatio(palette.onSurfaceMuted, palette.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(palette.onSurfaceMuted, palette.surfaceMuted),
            greaterThanOrEqualTo(4.5),
          );
        });

        test('text on the primary colour reaches AA', () {
          expect(
            contrastRatio(palette.onPrimary, palette.primary),
            greaterThanOrEqualTo(4.5),
          );
        });

        for (final intent in PeykIntent.values) {
          test('${intent.name} reads on its own wash', () {
            final colors = palette.of(intent);
            expect(
              contrastRatio(colors.foreground, colors.background),
              greaterThanOrEqualTo(4.5),
            );
          });

          // A border is decorative here: what a chip means is carried by its
          // word and by the wash behind it, never by its edge alone, so WCAG's
          // 3:1 bar for a graphical object does not apply. What the bar does
          // catch is a border that has been set to the surface colour and
          // stopped being an edge at all — which makes a row of chips read as
          // one undifferentiated block.
          test('${intent.name} keeps an edge against the surface', () {
            final colors = palette.of(intent);
            expect(
              contrastRatio(colors.border, palette.surface),
              greaterThanOrEqualTo(1.3),
            );
          });
        }
      });
    }
  });
}
