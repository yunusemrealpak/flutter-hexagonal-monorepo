import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';
import 'package:test/test.dart';

void main() {
  group('UserPreferences', () {
    test(
      'defaults are Turkish, the device palette and unmetered-only sync',
      () {
        const preferences = UserPreferences.defaults();

        expect(preferences.language, LanguageTag.turkish);
        expect(preferences.theme, ThemePreference.system);
        expect(preferences.syncPolicy, SyncPolicy.unmeteredOnly);
      },
    );

    test('two sets holding the same choices are equal', () {
      const one = UserPreferences.defaults();
      const other = UserPreferences(
        language: LanguageTag.turkish,
        theme: ThemePreference.system,
        syncPolicy: SyncPolicy.unmeteredOnly,
      );

      expect(one, other);
      expect(one.hashCode, other.hashCode);
    });

    test('copyWith replaces one choice and keeps the rest', () {
      const before = UserPreferences.defaults();

      final after = before.copyWith(theme: ThemePreference.dark);

      expect(after.theme, ThemePreference.dark);
      expect(after.language, before.language);
      expect(after.syncPolicy, before.syncPolicy);
      expect(after, isNot(before));
    });
  });

  group('stored spellings', () {
    test('a theme round-trips through its name', () {
      for (final theme in ThemePreference.values) {
        expect(
          (ThemePreference.parse(theme.name)
                  as Success<ThemePreference, SettingsFailure>)
              .value,
          theme,
        );
      }
    });

    test('a sync policy round-trips through its name', () {
      for (final policy in SyncPolicy.values) {
        expect(
          (SyncPolicy.parse(policy.name)
                  as Success<SyncPolicy, SettingsFailure>)
              .value,
          policy,
        );
      }
    });

    test('an unknown spelling fails rather than defaulting', () {
      expect(
        ThemePreference.parse('midnight'),
        isA<Failed<ThemePreference, SettingsFailure>>(),
      );
      expect(
        SyncPolicy.parse('whenever'),
        isA<Failed<SyncPolicy, SettingsFailure>>(),
      );
    });
  });
}
