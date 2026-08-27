/// How far apart two things are, said as what the distance means.
///
/// A caller never names a number. `design_tokens` holds the scale and this
/// enum says which step a situation calls for, which is the same split the
/// intent vocabulary makes: the values are there, the words for choosing one
/// are here.
///
/// It also does what the spacing scale could not do on its own. `PeykSpacing`
/// offers seven values and a screen picking among them by size ends up
/// inconsistent with the screen next to it; four situations with names are a
/// choice somebody can get right without measuring anything.
enum PeykGapSize {
  /// Between a glyph and the word next to it.
  tight,

  /// Between two lines of the same thing.
  betweenLines,

  /// Between two things that belong together.
  betweenRows,

  /// Between two groups.
  betweenGroups,
}
