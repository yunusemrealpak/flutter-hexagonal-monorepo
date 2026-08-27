/// The corner radii, in logical pixels.
///
/// Four values, and the largest one is not a number a caller should guess:
/// [pill] is deliberately far larger than any control this product draws, so
/// that a fully rounded end stays fully rounded when the control's height
/// changes.
abstract final class PeykRadius {
  /// 0 — a square corner, for something that meets the edge of the screen.
  static const double none = 0;

  /// 4 — a field, a small chip.
  static const double sm = 4;

  /// 8 — a card, a button.
  static const double md = 8;

  /// 16 — a sheet or a dialog.
  static const double lg = 16;

  /// 999 — both ends fully rounded, whatever the height is.
  static const double pill = 999;
}
