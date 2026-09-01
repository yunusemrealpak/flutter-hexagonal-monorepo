import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:settings_api/settings_api.dart';

import 'alerts_controller.dart';
import 'alerts_state.dart';
import 'settings_controller.dart';
import 'settings_state.dart';
import 'settings_strings.dart';

/// Where somebody chooses how the product behaves.
///
/// **Signing out arrives as a callback**, and it is the same shape as
/// `ProofCaptureScreen.onCaptureSignature` for the same reason. Ending a
/// session is identity's operation and the destination afterwards is the
/// app's decision; §2.4 forbids this package from knowing either. So the app
/// supplies the action, this screen offers the button, and an app that signs
/// out somewhere else passes nothing and no button is drawn. `settings` still
/// does not depend on `identity_api`.
///
/// **The alerts section arrives the same way**, as an optional controller. An
/// app that composes no alert channel capable of opening — `app_dispatcher`
/// answers every open with `AlertsRefused`, because a desk is not a device
/// that gets alerted — passes nothing and no switch is drawn. A control that
/// cannot work is worse than an absent one: somebody taps it, nothing happens,
/// and they conclude the product is broken.
final class SettingsScreen extends StatefulWidget {
  /// Creates the screen over [controller].
  const SettingsScreen({
    required this.controller,
    this.alerts,
    this.onSignOut,
    super.key,
  });

  /// What drives it.
  final SettingsController controller;

  /// What drives the alerts section, when this app has one to draw.
  final AlertsController? alerts;

  /// Ends the session, when this app offers that here.
  final VoidCallback? onSignOut;

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

  /// Which string a notifications failure should be shown as.
  ///
  /// Exhaustive over `NotificationsFailure` even though four of its cases
  /// cannot reach this screen — it holds no inbox. That is the cost of the
  /// union being one hierarchy, and it is the right cost: the day a case *can*
  /// arrive here, this stops compiling instead of falling through to a
  /// sentence about something else.
  @visibleForTesting
  static String describeAlerts(NotificationsFailure failure) =>
      switch (failure) {
        AlertsRefused() => SettingsStrings.alertsFailureRefused,
        AlertsUnreachable() => SettingsStrings.alertsFailureUnreachable,
        // AlertsBlocked is not given a sentence of its own here. Reading the
        // state back after a blocked open answers AlertsUnavailable, and that
        // draws the section that sends somebody to the system settings — a
        // whole treatment rather than a line of text.
        AlertsBlocked() => SettingsStrings.alertsBlocked,
        AlertStateUnavailable() ||
        InboxUnavailable() ||
        NotificationMissing() ||
        MalformedNotification() => SettingsStrings.alertsFailureUnavailable,
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

    final signOut = widget.onSignOut;

    return PeykScreen(
      title: strings.resolve(SettingsStrings.title),
      scrollable: true,
      // The sign-out button sits beside the state rather than inside it. A
      // person whose preferences failed to load is exactly the person who
      // might want to sign out and back in, and putting the button in the
      // switch would take it away in the one state where it is most wanted.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListenableBuilder(
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
          if (widget.alerts case final alerts?) ...[
            const PeykGap.vertical(PeykGapSize.betweenGroups),
            _AlertsSection(controller: alerts),
          ],
          if (signOut != null) ...[
            const PeykGap.vertical(PeykGapSize.betweenGroups),
            PeykButton(
              label: strings.resolve(SettingsStrings.signOut),
              onPressed: signOut,
              tone: PeykButtonTone.destructive,
            ),
          ],
        ],
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

/// The alerts switch, and the two states that are not a switch.
///
/// A `StatefulWidget` because it starts its own read and, unlike the choices
/// beside it, has a reason to read again while it is on screen: coming back
/// from the operating system's settings page changes the answer without the
/// application doing anything. `AppLifecycleListener` is what notices, and
/// without it the button that sends somebody there would appear to do nothing
/// when they came back.
class _AlertsSection extends StatefulWidget {
  const _AlertsSection({required this.controller});

  final AlertsController controller;

  @override
  State<_AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<_AlertsSection> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(widget.controller.load()),
    );
    unawaited(widget.controller.load());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = PeykStrings.of(context);

    return PeykSection(
      title: strings.resolve(SettingsStrings.alertsSection),
      children: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => switch (widget.controller.state) {
            AlertsLoading() => const PeykLoadingView(),
            AlertsUnreadable(:final failure) => PeykFailureView(
              message: strings.resolve(
                SettingsScreen.describeAlerts(failure),
              ),
              onRetry: () => unawaited(widget.controller.load()),
            ),
            // The one state that is not a control. A switch here would be the
            // button that does nothing which `AlertsBlocked` exists as a
            // separate case to prevent.
            AlertsSettled(alerts: AlertsUnavailable()) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PeykText.body(strings.resolve(SettingsStrings.alertsBlocked)),
                const PeykGap.vertical(PeykGapSize.betweenLines),
                PeykButton(
                  label: strings.resolve(SettingsStrings.alertsOpenSettings),
                  onPressed: () =>
                      unawaited(widget.controller.openSystemSettings()),
                ),
              ],
            ),
            AlertsSettled(:final alerts, :final changing, :final failure) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PeykSwitchRow(
                    label: strings.resolve(SettingsStrings.alertsToggle),
                    description: strings.resolve(
                      SettingsStrings.alertsExplanation,
                    ),
                    value: alerts is AlertsOpen,
                    onChanged: changing
                        ? null
                        : (on) => unawaited(widget.controller.choose(on: on)),
                  ),
                  if (failure != null) ...[
                    const PeykGap.vertical(PeykGapSize.betweenLines),
                    PeykText.caption(
                      strings.resolve(SettingsScreen.describeAlerts(failure)),
                    ),
                  ],
                ],
              ),
          },
        ),
      ],
    );
  }
}
