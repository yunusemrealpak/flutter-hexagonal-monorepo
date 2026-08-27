import 'dart:ui';

/// One step of the type scale, as the four numbers a text style is built from.
///
/// Not a `TextStyle`. A `TextStyle` carries a colour, and a colour depends on
/// which palette is in force and what the text is sitting on — decisions this
/// package cannot make. Keeping the two apart is what stops a token from
/// quietly becoming a component: `design_system` combines this with a
/// `PeykPalette` slot and produces the style.
final class PeykTypeToken {
  /// Creates a step of the scale.
  const PeykTypeToken({
    required this.fontSize,
    required this.height,
    required this.fontWeight,
    this.letterSpacing = 0,
  });

  /// The size in logical pixels.
  final double fontSize;

  /// Line height as a multiple of [fontSize].
  ///
  /// A multiple rather than an absolute, so that a person who has turned text
  /// scaling up gets the leading scaled with it.
  final double height;

  /// How heavy the face is drawn.
  final FontWeight fontWeight;

  /// Extra tracking, in logical pixels. Zero for every step but
  /// `PeykTypeScale.caption`, which needs a little to stay legible at 12.
  final double letterSpacing;
}
