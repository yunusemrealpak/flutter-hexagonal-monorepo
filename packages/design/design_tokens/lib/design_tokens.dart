/// The product's design decisions, as values.
///
/// This package has one dependency — the Flutter SDK, for `Color`,
/// `FontWeight` and `Brightness` — and section 2 of docs/DEPENDENCY_RULES.md
/// gives it no others. It declares no widget, builds no theme, and knows
/// nothing about what the product does: the vocabulary here is `success` and
/// `danger`, never `delivered` and `overdue`.
///
/// `design_system` is the only package that reads it directly. A presentation
/// package uses the components rather than the numbers, which is what keeps a
/// change of palette from being a change to fourteen packages.
library;

export 'src/peyk_breakpoint.dart';
export 'src/peyk_intent.dart';
export 'src/peyk_intent_colors.dart';
export 'src/peyk_motion.dart';
export 'src/peyk_palette.dart';
export 'src/peyk_radius.dart';
export 'src/peyk_spacing.dart';
export 'src/peyk_type_scale.dart';
export 'src/peyk_type_token.dart';
