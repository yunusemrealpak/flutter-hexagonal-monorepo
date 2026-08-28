/// The spacing scale, in logical pixels.
///
/// A four-point scale with named steps rather than free numbers. The point is
/// not that 12 is better than 13; it is that a screen built from six values
/// lines up with every other screen, and a screen built from arbitrary numbers
/// lines up with nothing.
///
/// There is deliberately no `xxs`. Anything smaller than [xs] is a hairline,
/// and a hairline is a border rather than a gap.
abstract final class PeykSpacing {
  /// No gap. Named so that a conditional gap reads as a decision.
  static const double none = 0;

  /// 4 — between a glyph and the word next to it.
  static const double xs = 4;

  /// 8 — between two lines of the same thing.
  static const double sm = 8;

  /// 12 — inside a control, between its edge and its label.
  static const double md = 12;

  /// 16 — between two things that belong together.
  static const double lg = 16;

  /// 24 — between two groups.
  static const double xl = 24;

  /// 32 — between a screen's edge and everything on it.
  static const double xxl = 32;
}
