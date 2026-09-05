import 'package:core_kernel/core_kernel.dart';

import '../failures/settings_failure.dart';

/// The language a person wants to be spoken to in, as a BCP 47 tag.
///
/// Two forms are accepted: a bare language subtag, `tr`, and a language with a
/// region, `en-GB`. That is the whole of BCP 47 this product uses, and
/// accepting more of the grammar than the product can act on would mean
/// storing tags no localisation file answers to.
///
/// Normalisation follows the specification rather than taste: the language
/// subtag is lower-cased and the region subtag upper-cased, so `EN-gb` and
/// `en-GB` are the same value rather than two rows that disagree.
///
/// **Which tags the product actually ships is not a rule of this type.** A
/// well-formed tag with no translation behind it is a deployment question that
/// changes with every release; making it a construction invariant here would
/// mean a person's stored preference became unreadable the day a language was
/// withdrawn. `settings_core` resolves a stored tag against what is available
/// and falls back — see `ResolveLanguage`.
final class LanguageTag extends ValueObject<String> {
  const LanguageTag._(super.value);

  /// Turkish, the product's default.
  ///
  /// A `const` rather than a parse at every call site: the default has to be
  /// available where no `Result` can be unwrapped — in `UserPreferences`'
  /// const constructor — and a value the type itself declares cannot be
  /// invalid.
  static const turkish = LanguageTag._('tr');

  /// Reads a language tag from [raw].
  static Result<LanguageTag, SettingsFailure> parse(String raw) {
    final trimmed = raw.trim();
    final parts = trimmed.split('-');
    if (parts.length > 2) {
      return Failed(
        MalformedPreference(
          field: 'language',
          reason: '"$trimmed" carries more subtags than this product reads',
        ),
      );
    }

    final language = parts.first;
    if (!_isAlpha(language) || language.length < 2 || language.length > 3) {
      return Failed(
        MalformedPreference(
          field: 'language',
          reason: '"$language" is not a two or three letter language subtag',
        ),
      );
    }
    if (parts.length == 1) {
      return Success(LanguageTag._(language.toLowerCase()));
    }

    final region = parts[1];
    if (!_isAlpha(region) || region.length != 2) {
      return Failed(
        MalformedPreference(
          field: 'language',
          reason: '"$region" is not a two letter region subtag',
        ),
      );
    }
    return Success(
      LanguageTag._('${language.toLowerCase()}-${region.toUpperCase()}'),
    );
  }

  /// The language subtag on its own, without the region.
  ///
  /// What a lookup falls back to when `en-GB` has no bundle and `en` does.
  String get language => value.split('-').first;

  static bool _isAlpha(String subtag) {
    if (subtag.isEmpty) {
      return false;
    }
    for (final unit in subtag.codeUnits) {
      final isUpper = unit >= 0x41 && unit <= 0x5A;
      final isLower = unit >= 0x61 && unit <= 0x7A;
      if (!isUpper && !isLower) {
        return false;
      }
    }
    return true;
  }
}
