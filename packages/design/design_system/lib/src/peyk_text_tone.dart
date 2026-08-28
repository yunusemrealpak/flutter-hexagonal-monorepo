/// How loud a piece of text is, within one palette.
///
/// Separate from `PeykIntent`: an intent says what something means, a tone says
/// how much of the reader's attention it is asking for. A timestamp is
/// [muted] and neutral; a failed delivery is [standard] and danger.
enum PeykTextTone {
  /// Full contrast against the surface. The default.
  standard,

  /// Reduced contrast: a timestamp, a hint, a disabled label.
  muted,

  /// Drawn to sit on the primary colour rather than on a surface.
  onPrimary,
}
