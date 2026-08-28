import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

import 'peyk_intent.dart';
import 'peyk_text_tone.dart';
import 'peyk_theme.dart';
import 'peyk_type_style.dart';

/// Text at one step of the type scale, in one tone, optionally carrying an
/// intent.
///
/// Six named constructors and no free `TextStyle`. A presentation package that
/// could pass its own style would be a presentation package able to invent a
/// seventh size, and the scale would stop being a scale on the day somebody
/// needed 17.
final class PeykText extends StatelessWidget {
  /// A screen's own title.
  const PeykText.display(
    this.data, {
    this.tone = PeykTextTone.standard,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.display;

  /// The heading over a group.
  const PeykText.title(
    this.data, {
    this.tone = PeykTextTone.standard,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.title;

  /// Ordinary text.
  const PeykText.body(
    this.data, {
    this.tone = PeykTextTone.standard,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.body;

  /// Ordinary text, when this line is the point of the group.
  const PeykText.bodyStrong(
    this.data, {
    this.tone = PeykTextTone.standard,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.bodyStrong;

  /// What a control is called.
  const PeykText.label(
    this.data, {
    this.tone = PeykTextTone.standard,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.label;

  /// The small print.
  const PeykText.caption(
    this.data, {
    this.tone = PeykTextTone.muted,
    this.intent,
    this.textAlign,
    this.maxLines,
    super.key,
  }) : _token = PeykTypeScale.caption;

  /// The sentence to draw. Already resolved: a widget never holds a key.
  final String data;

  /// How much attention it is asking for.
  final PeykTextTone tone;

  /// What it means, if it means anything in particular.
  ///
  /// Wins over [tone] when both are set, because an intent is a statement
  /// about the content and a tone is a statement about its prominence — and a
  /// muted danger is a warning nobody reads.
  final PeykIntent? intent;

  /// How the lines are aligned within the available width.
  final TextAlign? textAlign;

  /// How many lines before it is cut off. Null for as many as it takes.
  final int? maxLines;

  final PeykTypeToken _token;

  @override
  Widget build(BuildContext context) {
    final palette = PeykTheme.of(context).palette;
    final color = switch ((intent, tone)) {
      (final PeykIntent intent, _) => palette.colorsFor(intent).foreground,
      (_, PeykTextTone.standard) => palette.onSurface,
      (_, PeykTextTone.muted) => palette.onSurfaceMuted,
      (_, PeykTextTone.onPrimary) => palette.onPrimary,
    };

    return Text(
      data,
      style: _token.toTextStyle(color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
