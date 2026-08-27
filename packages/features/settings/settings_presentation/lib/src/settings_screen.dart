import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:settings_api/settings_api.dart';

import 'settings_controller.dart';
import 'settings_state.dart';
import 'settings_strings.dart';

/// Where somebody chooses how the product behaves.
final class SettingsScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const SettingsScreen({required this.controller, super.key});

  /// What drives it.
  final SettingsController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Which string a failure should be shown as.
  ///
  /// Exhaustive over `SettingsFailure`, which is the point of it being sealed:
  /// the day settings learns a new way to fail, this stops compiling instead
  /// of showing somebody the wrong sentence.
  @visibleForTesting
  static String describe(SettingsFailure failure) => switch (failure) {
    PreferencesUnavailable() => SettingsStrings.failureUnavailable,
    PreferencesCorrupted() => SettingsStrings.failureCorrupted,
    MalformedPreference() => SettingsStrings.failureMalformed,
  };

  /// The arguments [failure] contributes to its own message.
  ///
  /// Separate from [describe] because the key and its arguments answer
  /// different questions — which sentence, and what goes in the holes. Folding
  /// them into one record would make the common case, a failure with no
  /// arguments at all, carry an empty map at every call site.
  @visibleForTesting
  static Map<String, Object?> argumentsFor(SettingsFailure failure) =>
      switch (failure) {
        MalformedPreference(:final field) => {'field': field},
        PreferencesUnavailable() || PreferencesCorrupted() => const {},
      };
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.watch();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykScreen(
      title: strings.resolve(SettingsStrings.title),
      scrollable: true,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          SettingsIdle() || SettingsLoading() => const PeykLoadingView(),
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
          SettingsFailed(:final failure) => PeykFailureView(
            message: strings.resolve(
              SettingsScreen.describe(failure),
              arguments: SettingsScreen.argumentsFor(failure),
            ),
            onRetry: () => unawaited(widget.controller.load()),
          ),
        },
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PeykSection(
          title: strings.resolve(SettingsStrings.languageSection),
          children: [
            for (final language in SettingsStrings.offeredLanguages)
              PeykOptionRow(
                label: strings.resolve(SettingsStrings.language(language)),
                selected: preferences.language == language,
                onTap: busy ? null : () => controller.chooseLanguage(language),
              ),
          ],
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        PeykSection(
          title: strings.resolve(SettingsStrings.themeSection),
          children: [
            for (final theme in ThemePreference.values)
              PeykOptionRow(
                label: strings.resolve(SettingsStrings.theme(theme)),
                selected: preferences.theme == theme,
                onTap: busy ? null : () => controller.chooseTheme(theme),
              ),
          ],
        ),
        const PeykGap.vertical(PeykGapSize.betweenGroups),
        PeykSection(
          title: strings.resolve(SettingsStrings.syncSection),
          children: [
            for (final policy in SyncPolicy.values)
              PeykOptionRow(
                label: strings.resolve(SettingsStrings.syncPolicy(policy)),
                selected: preferences.syncPolicy == policy,
                onTap: busy ? null : () => controller.chooseSyncPolicy(policy),
              ),
          ],
        ),
      ],
    );
  }
}
