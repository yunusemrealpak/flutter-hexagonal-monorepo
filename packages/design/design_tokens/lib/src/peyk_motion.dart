/// How long things take.
///
/// Three durations and a zero. The zero is not a placeholder: a device with
/// "reduce motion" on gets [none] for every one of these, and having it in the
/// scale means that path is a substitution rather than a branch in every
/// animated widget.
abstract final class PeykMotion {
  /// No animation. What every duration becomes when motion is reduced.
  static const Duration none = Duration.zero;

  /// 120ms — a colour changing under a finger.
  static const Duration quick = Duration(milliseconds: 120);

  /// 220ms — something appearing or moving within a screen.
  static const Duration standard = Duration(milliseconds: 220);

  /// 360ms — a whole screen or sheet arriving.
  static const Duration slow = Duration(milliseconds: 360);
}
