import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:settings_api/settings_api.dart';

import 'settings_controller.dart';
import 'settings_state.dart';

/// Where somebody chooses how the product behaves.
///
/// Deliberately plain: no colours, no typography, no spacing scale. Those come
/// from `design_system`, which arrives in phase 7. What this file is for is
/// the wiring — a screen that renders a sealed state and calls a port, and
/// knows neither a use case nor an adapter.
final class SettingsScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const SettingsScreen({required this.controller, super.key});

  /// What drives it.
  final SettingsController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Turns a failure into something a person can act on.
  ///
  /// Exhaustive over `SettingsFailure`, which is the point of it being sealed:
  /// the day settings learns a new way to fail, this stops compiling instead
  /// of showing somebody the wrong sentence.
  static String describe(SettingsFailure failure) => switch (failure) {
    PreferencesUnavailable() => 'Your settings could not be reached.',
    PreferencesCorrupted() => 'Your settings could not be read.',
    MalformedPreference(:final field) => 'That $field cannot be used.',
  };

  /// The languages this screen offers.
  ///
  /// A fixed list here is a placeholder for what an app will supply in phase
  /// 7, when localisation exists and `ResolveLanguage` has something to
  /// resolve against. It is a `const` rather than a parse, because a screen
  /// that had to unwrap three `Result`s to draw a list would be hiding the
  /// interesting failure behind an uninteresting one.
  static const List<LanguageTag> offeredLanguages = [LanguageTag.turkish];
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state) {
      SettingsIdle() || SettingsLoading() => const Text('Loading…'),
      SettingsReady(:final preferences) => _Choices(
        preferences: preferences,
        controller: widget.controller,
        busy: false,
      ),
      SettingsSaving(:final preferences) => _Choices(
        preferences: preferences,
        controller: widget.controller,
        busy: true,
      ),
      SettingsFailed(:final failure) => Text(
        SettingsScreen.describe(failure),
      ),
    },
  );
}

/// The three choices, and the state of the write behind them.
///
/// [busy] disables the rows rather than hiding them. A settings screen that
/// emptied itself for the duration of a write would flicker on every tap, and
/// somebody would tap the same row twice because the first tap left no trace.
class _Choices extends StatelessWidget {
  const _Choices({
    required this.preferences,
    required this.controller,
    required this.busy,
  });

  final UserPreferences preferences;
  final SettingsController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final language in SettingsScreen.offeredLanguages)
        _Row(
          label: 'language.${language.value}',
          selected: preferences.language == language,
          onTap: busy ? null : () => controller.chooseLanguage(language),
        ),
      for (final theme in ThemePreference.values)
        _Row(
          label: 'theme.${theme.name}',
          selected: preferences.theme == theme,
          onTap: busy ? null : () => controller.chooseTheme(theme),
        ),
      for (final policy in SyncPolicy.values)
        _Row(
          label: 'sync.${policy.name}',
          selected: preferences.syncPolicy == policy,
          onTap: busy ? null : () => controller.chooseSyncPolicy(policy),
        ),
    ],
  );
}

/// One selectable option.
///
/// The label is a key rather than a sentence — `theme.dark`, not "Dark" —
/// because the strings belong to the app's localisation, which arrives in
/// phase 7. Writing English here would mean deleting it then, and in the
/// meantime it would read as a decision nobody made.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Semantics(
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: Text(label),
    ),
  );
}
