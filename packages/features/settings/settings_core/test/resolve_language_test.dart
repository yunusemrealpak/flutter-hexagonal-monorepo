import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';
import 'package:test/test.dart';

LanguageTag tag(String raw) =>
    (LanguageTag.parse(raw) as Success<LanguageTag, SettingsFailure>).value;

void main() {
  group('ResolveLanguage', () {
    test('keeps a tag this build ships', () {
      final resolve = ResolveLanguage(
        available: {tag('tr'), tag('en-GB')},
        fallback: LanguageTag.turkish,
      );

      expect(resolve(tag('en-GB')), tag('en-GB'));
    });

    test('falls back to the same language in another region', () {
      final resolve = ResolveLanguage(
        available: {tag('tr'), tag('en')},
        fallback: LanguageTag.turkish,
      );

      expect(resolve(tag('en-GB')), tag('en'));
    });

    test('falls back to the product default when the language is absent', () {
      final resolve = ResolveLanguage(
        available: {tag('tr')},
        fallback: LanguageTag.turkish,
      );

      expect(resolve(tag('de')), LanguageTag.turkish);
    });

    test('a stored preference outliving its translation is not an error', () {
      final resolve = ResolveLanguage(
        available: {tag('tr')},
        fallback: LanguageTag.turkish,
      );

      expect(() => resolve(tag('en-GB')), returnsNormally);
    });
  });
}
