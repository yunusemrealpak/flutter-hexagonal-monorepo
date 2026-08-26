import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:settings_api/settings_api.dart';

/// The stored shape of a set of preferences.
///
/// A DTO, and it stays on this side of the ports. `UserPreferences` never
/// learns that it is written as JSON under a key, and this type never appears
/// in a signature `settings_api` declares — which is the whole of rule 1.2.10
/// in a package small enough to see both ends of it at once.
///
/// Hand-written rather than generated. Three string fields do not pay for a
/// `build.yaml`, a `build_runner` dev dependency and a generated file in every
/// diff; `json_serializable` earns its place when the shape grows past what is
/// pleasant to read.
final class PreferencesDto {
  /// Creates the DTO.
  const PreferencesDto({
    required this.language,
    required this.theme,
    required this.syncPolicy,
  });

  /// Builds the DTO that carries [preferences].
  factory PreferencesDto.fromDomain(UserPreferences preferences) =>
      PreferencesDto(
        language: preferences.language.value,
        theme: preferences.theme.name,
        syncPolicy: preferences.syncPolicy.name,
      );

  /// Reads one from a decoded JSON object.
  ///
  /// Returns `null` rather than throwing when a field is missing or is not a
  /// string. A record written by a version of the product that spelled things
  /// differently is a corrupt record, and the caller turns `null` into
  /// [PreferencesCorrupted] — no exception crosses the port above it.
  static PreferencesDto? fromJson(Map<String, Object?> json) {
    final language = json['language'];
    final theme = json['theme'];
    final syncPolicy = json['syncPolicy'];
    if (language is! String || theme is! String || syncPolicy is! String) {
      return null;
    }
    return PreferencesDto(
      language: language,
      theme: theme,
      syncPolicy: syncPolicy,
    );
  }

  /// Reads one from the string a key-value store gave back.
  ///
  /// The `FormatException` `jsonDecode` throws is caught here, at the edge, so
  /// that malformed text is one more corrupt record rather than an exception
  /// travelling up through a use case.
  static PreferencesDto? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? fromJson(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  /// The language tag, as it was stored.
  final String language;

  /// The palette, as it was stored.
  final String theme;

  /// The synchronisation policy, as it was stored.
  final String syncPolicy;

  /// The text to store.
  String encode() => jsonEncode({
    'language': language,
    'theme': theme,
    'syncPolicy': syncPolicy,
  });

  /// The preferences this DTO carries, or a failure describing the first field
  /// that could not be read.
  ///
  /// Every one of the three parses can fail, so they are chained with
  /// `flatMap`: the first refusal is the answer and the rest are not
  /// attempted. Reporting all three at once would be a nicer error message for
  /// a form and is the wrong shape here — nobody types this, a previous
  /// version of the product wrote it.
  Result<UserPreferences, SettingsFailure> toDomain() =>
      LanguageTag.parse(language).flatMap(
        (tag) => ThemePreference.parse(theme).flatMap(
          (palette) => SyncPolicy.parse(syncPolicy).map(
            (policy) => UserPreferences(
              language: tag,
              theme: palette,
              syncPolicy: policy,
            ),
          ),
        ),
      );
}
