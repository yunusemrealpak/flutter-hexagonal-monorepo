import 'package:settings_api/settings_api.dart';

/// Every string key this package asks an app to answer.
///
/// Three of the groups are computed from enums rather than written out, and
/// that is the point of them being here: adding a `SyncPolicy` adds a row to
/// the screen *and* a key to [all], so the app's coverage test fails until
/// somebody writes the sentence. A hand-written list would have let the new
/// row ship showing its own key.
abstract final class SettingsStrings {
  /// The settings screen's title.
  static const String title = 'settings.title';

  /// The heading over the language choices.
  static const String languageSection = 'settings.language.section';

  /// The heading over the palette choices.
  static const String themeSection = 'settings.theme.section';

  /// The heading over the sync-policy choices.
  static const String syncSection = 'settings.sync.section';

  /// The heading over the alerts switch.
  ///
  /// Alerts belong to `notifications`, and these keys are declared here
  /// anyway, for the reason [signOut] gives: a key belongs to the screen that
  /// asks for it. Borrowing `NotificationsStrings` was never possible either —
  /// a presentation package may not depend on another presentation package.
  static const String alertsSection = 'settings.alerts.section';

  /// Why somebody would want alerts on. Sits under the switch's label.
  ///
  /// The one string on this screen that has to be persuasive rather than
  /// merely accurate. It is the whole priming step: the operating system's own
  /// prompt appears immediately after the tap, so an explanation anywhere else
  /// is an explanation nobody is reading when they decide.
  static const String alertsExplanation = 'settings.alerts.explanation';

  /// The label on the alerts switch.
  static const String alertsToggle = 'settings.alerts.toggle';

  /// Shown when the app may not ask for the notification permission again.
  static const String alertsBlocked = 'settings.alerts.blocked';

  /// The label on the button that opens the operating system's settings.
  static const String alertsOpenSettings = 'settings.alerts.openSettings';

  /// Alerts were refused, and can be asked for again.
  static const String alertsFailureRefused = 'settings.alerts.failure.refused';

  /// This device could not be registered for alerts.
  static const String alertsFailureUnreachable =
      'settings.alerts.failure.unreachable';

  /// Alerts could not be reached at all.
  static const String alertsFailureUnavailable =
      'settings.alerts.failure.unavailable';

  /// The label on the button that ends the session.
  ///
  /// Declared here rather than in `identity_presentation` because the button
  /// is on this screen, and a key belongs to the screen that asks for it. The
  /// operation behind it is identity's and reaches this package as a callback
  /// — §2.4.
  static const String signOut = 'settings.signOut';

  /// Settings could not be reached.
  static const String failureUnavailable = 'settings.failure.unavailable';

  /// The stored settings could not be read.
  static const String failureCorrupted = 'settings.failure.corrupted';

  /// One stored field could not be used. Takes a `field` argument.
  static const String failureMalformed = 'settings.failure.malformed';

  /// The key for one language option.
  static String language(LanguageTag tag) => 'settings.language.${tag.value}';

  /// The key for one palette option.
  static String theme(ThemePreference theme) => 'settings.theme.${theme.name}';

  /// The key for one sync-policy option.
  static String syncPolicy(SyncPolicy policy) => 'settings.sync.${policy.name}';

  /// Every key above, for an app's coverage test.
  ///
  /// `final` rather than `const`, because the option keys are derived from the
  /// enums they label. That derivation is what makes the list stay true.
  static final List<String> all = [
    title,
    languageSection,
    themeSection,
    syncSection,
    alertsSection,
    alertsExplanation,
    alertsToggle,
    alertsBlocked,
    alertsOpenSettings,
    alertsFailureRefused,
    alertsFailureUnreachable,
    alertsFailureUnavailable,
    signOut,
    failureUnavailable,
    failureCorrupted,
    failureMalformed,
    for (final tag in offeredLanguages) language(tag),
    for (final value in ThemePreference.values) theme(value),
    for (final value in SyncPolicy.values) syncPolicy(value),
  ];

  /// The languages this screen offers.
  ///
  /// A fixed list rather than a parse, because a screen that had to unwrap
  /// three `Result`s to draw a list would be hiding the interesting failure
  /// behind an uninteresting one. It lives here rather than on the screen so
  /// that [all] and the rows it labels cannot disagree.
  static const List<LanguageTag> offeredLanguages = [LanguageTag.turkish];
}
