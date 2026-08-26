import 'package:core_ports/core_ports.dart';
import 'package:settings_api/settings_api.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late SettingsHarness harness;

  setUp(() => harness = SettingsHarness());
  tearDown(() => harness.facade.dispose());

  group('reading preferences', () {
    test('somebody who has chosen nothing gets the defaults', () async {
      final read = await harness.facade.preferencesOf(SettingsHarness.courier);

      expect(SettingsHarness.valueOf(read), const UserPreferences.defaults());
    });

    test('a record that cannot be read falls back to the defaults', () async {
      await harness.preStore('{"language":"tr","theme":"midnight"}');

      final read = await harness.facade.preferencesOf(SettingsHarness.courier);

      expect(SettingsHarness.valueOf(read), const UserPreferences.defaults());
      expect(harness.logger.recordsAt(LogLevel.warning), hasLength(1));
    });

    test('text that is not JSON at all is a corrupt record', () async {
      await harness.preStore('not json');

      final read = await harness.facade.preferencesOf(SettingsHarness.courier);

      expect(SettingsHarness.valueOf(read), const UserPreferences.defaults());
    });

    test('an unreachable store is a failure, not the defaults', () async {
      harness.keyValue.failNextWith(const StoreUnavailable(detail: 'locked'));

      final read = await harness.facade.preferencesOf(SettingsHarness.courier);

      expect(SettingsHarness.failureOf(read), isA<PreferencesUnavailable>());
      expect(harness.logger.records, isEmpty);
    });
  });

  group('changing a preference', () {
    test('a choice survives being read back', () async {
      await harness.facade.chooseTheme(
        SettingsHarness.courier,
        ThemePreference.dark,
      );

      final read = await harness.facade.preferencesOf(SettingsHarness.courier);

      expect(SettingsHarness.valueOf(read).theme, ThemePreference.dark);
    });

    test('changing one preference leaves the others alone', () async {
      await harness.facade.chooseSyncPolicy(
        SettingsHarness.courier,
        SyncPolicy.manual,
      );

      final changed = await harness.facade.chooseTheme(
        SettingsHarness.courier,
        ThemePreference.light,
      );

      final preferences = SettingsHarness.valueOf(changed);
      expect(preferences.theme, ThemePreference.light);
      expect(preferences.syncPolicy, SyncPolicy.manual);
      expect(preferences.language, LanguageTag.turkish);
    });

    test(
      'a corrupt record is replaced by the change that lands on it',
      () async {
        await harness.preStore('not json');

        await harness.facade.chooseTheme(
          SettingsHarness.courier,
          ThemePreference.dark,
        );

        harness.logger.clear();
        final read = await harness.facade.preferencesOf(
          SettingsHarness.courier,
        );

        expect(SettingsHarness.valueOf(read).theme, ThemePreference.dark);
        expect(
          harness.logger.records,
          isEmpty,
          reason: 'the unreadable record is gone, so nothing warns about it',
        );
      },
    );

    test('a failed write is not announced as a change', () async {
      final announced = <UserPreferences>[];
      harness.facade.changes().listen(announced.add);
      harness.keyValue.failNextWith(const StoreOutOfSpace());

      final changed = await harness.facade.chooseTheme(
        SettingsHarness.courier,
        ThemePreference.dark,
      );
      await pumpEventQueue();

      expect(SettingsHarness.failureOf(changed), isA<PreferencesUnavailable>());
      expect(announced, isEmpty);
    });

    test('a recorded change is announced once', () async {
      final announced = <UserPreferences>[];
      harness.facade.changes().listen(announced.add);

      await harness.facade.chooseLanguage(
        SettingsHarness.courier,
        LanguageTag.turkish,
      );
      await pumpEventQueue();

      expect(announced, hasLength(1));
      expect(announced.single.language, LanguageTag.turkish);
    });
  });
}
