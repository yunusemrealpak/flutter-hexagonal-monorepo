import 'package:core_kernel/core_kernel.dart';

import '../failures/settings_failure.dart';

/// Which palette a person wants, or that they want the device to decide.
///
/// An enum rather than a boolean pair, because [system] is a real third answer
/// and not the absence of the other two: a person who has chosen it wants the
/// app to change when the phone does, which is a behaviour rather than an
/// unset field.
enum ThemePreference {
  /// Follow whatever the device reports.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark;

  /// Reads a preference from its stored spelling.
  ///
  /// Returns a `Result` rather than falling back to [system], because the
  /// caller is an adapter reading a record it wrote itself: a value that is
  /// not one of these three means the record is corrupt, and silently
  /// defaulting would hide a failed migration behind a preference nobody chose.
  static Result<ThemePreference, SettingsFailure> parse(String raw) {
    for (final value in values) {
      if (value.name == raw) {
        return Success(value);
      }
    }
    return Failed(
      MalformedPreference(
        field: 'theme',
        reason: '"$raw" is not one of ${values.map((v) => v.name).join(', ')}',
      ),
    );
  }
}
