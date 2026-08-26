import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';
import 'package:test/test.dart';

void main() {
  group('PreferencesDto', () {
    test('round-trips a full set of preferences', () {
      const preferences = UserPreferences(
        language: LanguageTag.turkish,
        theme: ThemePreference.dark,
        syncPolicy: SyncPolicy.manual,
      );

      final decoded = PreferencesDto.decode(
        PreferencesDto.fromDomain(preferences).encode(),
      );

      expect(decoded, isNotNull);
      expect(
        (decoded!.toDomain() as Success<UserPreferences, SettingsFailure>)
            .value,
        preferences,
      );
    });

    test('a missing field is an unreadable record rather than a throw', () {
      expect(PreferencesDto.decode('{"language":"tr"}'), isNull);
    });

    test('a field of the wrong type is an unreadable record', () {
      expect(
        PreferencesDto.decode(
          '{"language":"tr","theme":1,"syncPolicy":"manual"}',
        ),
        isNull,
      );
    });

    test('JSON that is not an object is an unreadable record', () {
      expect(PreferencesDto.decode('[1,2,3]'), isNull);
    });

    test('the first unreadable field is the failure, and it names itself', () {
      const dto = PreferencesDto(
        language: 'tr',
        theme: 'midnight',
        syncPolicy: 'never',
      );

      final failure =
          (dto.toDomain() as Failed<UserPreferences, SettingsFailure>).failure;

      expect(failure, isA<MalformedPreference>());
      expect((failure as MalformedPreference).field, 'theme');
    });
  });
}
