import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Turns a step of the type scale into a `TextStyle`.
///
/// This extension is the seam between the two design packages, and it is a
/// one-way street: `design_tokens` describes four numbers, `design_system`
/// decides what colour they are drawn in and hands the result to Flutter. A
/// token that already knew its colour would have to know which palette is in
/// force, which is a question only a widget tree can answer.
extension PeykTypeStyle on PeykTypeToken {
  /// Builds the style, drawn in [color].
  ///
  /// The colour is required rather than defaulted. A default would be a
  /// palette slot chosen here, once, for text that is sometimes on a surface,
  /// sometimes on a primary-coloured button and sometimes inside an intent
  /// wash — and the wrong one of those is invisible text.
  TextStyle toTextStyle(Color color) => TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
  );
}
