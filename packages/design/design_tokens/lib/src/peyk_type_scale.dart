import 'dart:ui';

import 'peyk_type_token.dart';

/// The type scale: six steps, and no seventh.
///
/// Six is not a target, it is what the product turned out to need. Every step
/// answers a question a screen actually asks — what is this screen, what is
/// this group, what does it say, which of these words matters, what is this
/// control called, and what is the small print. A scale with a step nobody can
/// name is a scale people pick from at random.
abstract final class PeykTypeScale {
  /// A screen's own title, used once per screen.
  static const PeykTypeToken display = PeykTypeToken(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// The heading over a group of rows.
  static const PeykTypeToken title = PeykTypeToken(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Ordinary text.
  static const PeykTypeToken body = PeykTypeToken(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Ordinary text, when one line of it is the point.
  static const PeykTypeToken bodyStrong = PeykTypeToken(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  /// What a control is called.
  static const PeykTypeToken label = PeykTypeToken(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// A timestamp, a hint, a count — the small print.
  static const PeykTypeToken caption = PeykTypeToken(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}
