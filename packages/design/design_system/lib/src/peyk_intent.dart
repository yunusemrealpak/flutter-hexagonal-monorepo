import 'package:design_tokens/design_tokens.dart';

/// What a piece of the interface is telling somebody, independent of what it
/// is telling them *about*.
///
/// This is the vocabulary a presentation package uses instead of a colour. A
/// feature maps its own sealed state onto it — a delivered shipment is
/// [success], an overdue incident is [danger] — and that mapping stays with
/// the feature that owns the state. Naming these `delivered` or `overdue`
/// would put a courier product's domain inside the design layer.
///
/// **It is declared here rather than in `design_tokens`, and the constitution
/// is what decided that.** Section 2 does not put `design_tokens` on the
/// presentation row, and rule S4 forbids this barrel from re-exporting another
/// package's URI — so a type a caller has to *name* cannot live there. That
/// turns out to be the right split on its own terms: `design_tokens` holds
/// five colour triples, and *which one a caller asks for* is a question about
/// this package's API rather than about the values.
enum PeykIntent {
  /// Nothing is being claimed. The default for text and containers.
  neutral,

  /// Something is worth reading but nothing is wrong.
  info,

  /// Something finished the way it was supposed to.
  success,

  /// Something needs a person's attention but has not failed.
  warning,

  /// Something failed, or is about to.
  danger,
}

/// Picks one of a palette's intent triples.
extension PeykPaletteIntent on PeykPalette {
  /// The colours for [intent].
  ///
  /// A total function over the enum rather than a map, so that adding an
  /// intent stops this compiling instead of returning null at one call site
  /// somebody has to find.
  PeykIntentColors colorsFor(PeykIntent intent) => switch (intent) {
    PeykIntent.neutral => neutral,
    PeykIntent.info => info,
    PeykIntent.success => success,
    PeykIntent.warning => warning,
    PeykIntent.danger => danger,
  };
}
