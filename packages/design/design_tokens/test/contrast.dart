import 'dart:math' as math;
import 'dart:ui';

/// The WCAG 2.1 contrast ratio between [a] and [b], from 1.0 to 21.0.
///
/// Written out here rather than pulled from a package because it is eight
/// lines and because design_tokens is allowed no third-party dependency at
/// all — including in its tests, where one would be harmless but would leave
/// the package's own pubspec claiming something the workspace does not.
double contrastRatio(Color a, Color b) {
  final first = _relativeLuminance(a);
  final second = _relativeLuminance(b);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
