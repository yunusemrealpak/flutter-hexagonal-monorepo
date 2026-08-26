import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageTag', () {
    test('accepts a bare language subtag and lower-cases it', () {
      final parsed = LanguageTag.parse('TR');

      expect(parsed, isA<Success<LanguageTag, SettingsFailure>>());
      expect(
        (parsed as Success<LanguageTag, SettingsFailure>).value.value,
        'tr',
      );
    });

    test('upper-cases the region and lower-cases the language', () {
      final parsed = LanguageTag.parse('EN-gb');

      expect(
        (parsed as Success<LanguageTag, SettingsFailure>).value.value,
        'en-GB',
      );
    });

    test('trims surrounding whitespace', () {
      final parsed = LanguageTag.parse('  tr  ');

      expect(
        (parsed as Success<LanguageTag, SettingsFailure>).value,
        LanguageTag.turkish,
      );
    });

    test('two spellings of the same tag are one value', () {
      final lower = LanguageTag.parse('en-gb');
      final upper = LanguageTag.parse('EN-GB');

      expect(
        (lower as Success<LanguageTag, SettingsFailure>).value,
        (upper as Success<LanguageTag, SettingsFailure>).value,
      );
    });

    test('language strips the region', () {
      final parsed =
          LanguageTag.parse('en-GB') as Success<LanguageTag, SettingsFailure>;

      expect(parsed.value.language, 'en');
    });

    test('refuses more subtags than this product reads', () {
      final parsed = LanguageTag.parse('en-Latn-GB');

      expect(parsed, isA<Failed<LanguageTag, SettingsFailure>>());
      expect(
        (parsed as Failed<LanguageTag, SettingsFailure>).failure,
        isA<MalformedPreference>(),
      );
    });

    test('refuses a non-alphabetic subtag', () {
      expect(
        LanguageTag.parse('t1'),
        isA<Failed<LanguageTag, SettingsFailure>>(),
      );
    });

    test('refuses a region that is not two letters', () {
      expect(
        LanguageTag.parse('en-GBR'),
        isA<Failed<LanguageTag, SettingsFailure>>(),
      );
    });

    test('refuses an empty tag', () {
      expect(
        LanguageTag.parse('   '),
        isA<Failed<LanguageTag, SettingsFailure>>(),
      );
    });
  });
}
