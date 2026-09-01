@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_presentation/settings_presentation.dart';

/// A `NotificationsFacade` this test steers.
///
/// A fake rather than a mock: it really holds a state and really changes it,
/// so the assertions below are about what the controller did rather than about
/// a script of calls. `notifications` ships no `_testing` package, so the
/// stand-in lives beside the tests that need it.
final class _Notifications implements NotificationsFacade {
  /// What the device currently reports.
  AlertState alerts = const AlertsClosed();

  /// Set to fail the next change, whichever way it goes.
  NotificationsFailure? failWith;

  /// Set to fail every read of the state.
  NotificationsFailure? failReadWith;

  /// Every actor `openAlertsFor` was called for, in order.
  final List<String> opened = [];

  /// Every actor `closeAlertsFor` was called for, in order.
  final List<String> closed = [];

  @override
  Future<Result<AlertState, NotificationsFailure>> alertStateFor(
    ActorId actor,
  ) async {
    final failure = failReadWith;
    return failure == null ? Success(alerts) : Failed(failure);
  }

  @override
  Future<Result<void, NotificationsFailure>> openAlertsFor(
    ActorId actor,
  ) async {
    opened.add(actor.value);
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    alerts = const AlertsOpen();
    return const Success(null);
  }

  @override
  Future<Result<void, NotificationsFailure>> closeAlertsFor(
    ActorId actor,
  ) async {
    closed.add(actor.value);
    final failure = _taken();
    if (failure != null) {
      return Failed(failure);
    }
    alerts = const AlertsClosed();
    return const Success(null);
  }

  @override
  Future<Result<List<InboxEntry>, NotificationsFailure>> inboxOf(
    ActorId actor,
  ) async => const Success([]);

  @override
  Future<Result<InboxEntry, NotificationsFailure>> markRead(
    ActorId actor,
    NotificationId id,
  ) async => Failed(NotificationMissing(id.value));

  @override
  Stream<int> unreadCount() => const Stream.empty();

  NotificationsFailure? _taken() {
    final failure = failWith;
    failWith = null;
    return failure;
  }
}

/// A `SettingsFacade` that answers the defaults and never fails.
///
/// The alerts section is what this file is about; the choices beside it only
/// have to be there.
final class _Settings implements SettingsFacade {
  @override
  Future<Result<UserPreferences, SettingsFailure>> preferencesOf(
    ActorId actor,
  ) async => const Success(UserPreferences.defaults());

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseLanguage(
    ActorId actor,
    LanguageTag language,
  ) async => const Success(UserPreferences.defaults());

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  ) async => const Success(UserPreferences.defaults());

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  ) async => const Success(UserPreferences.defaults());

  @override
  Stream<UserPreferences> changes() => const Stream.empty();
}

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

void main() {
  late _Notifications notifications;
  late int settingsOpened;

  AlertsController controllerFor() => AlertsController(
    notifications: notifications,
    actor: _courier,
    openSystemSettings: () async {
      settingsOpened++;
      return true;
    },
  );

  setUp(() {
    notifications = _Notifications();
    settingsOpened = 0;
  });

  group('AlertsController', () {
    test('reads the state it is given', () async {
      notifications.alerts = const AlertsOpen();
      final controller = controllerFor();

      await controller.load();

      expect(
        controller.state,
        isA<AlertsSettled>().having(
          (s) => s.alerts,
          'alerts',
          isA<AlertsOpen>(),
        ),
      );
      controller.dispose();
    });

    test('turning it on asks the facade to open alerts', () async {
      final controller = controllerFor();
      await controller.load();

      await controller.choose(on: true);

      expect(notifications.opened, ['courier-7']);
      expect(
        controller.state,
        isA<AlertsSettled>().having(
          (s) => s.alerts,
          'alerts',
          isA<AlertsOpen>(),
        ),
      );
      controller.dispose();
    });

    test('turning it off asks the facade to close them', () async {
      notifications.alerts = const AlertsOpen();
      final controller = controllerFor();
      await controller.load();

      await controller.choose(on: false);

      expect(notifications.closed, ['courier-7']);
      controller.dispose();
    });

    test('a refused change keeps the state the device actually has', () async {
      final controller = controllerFor();
      await controller.load();
      notifications.failWith = const AlertsRefused();

      await controller.choose(on: true);

      // The device did not open. Drawing the switch on because somebody asked
      // for it is how a control ends up lying about the thing it controls.
      expect(
        controller.state,
        isA<AlertsSettled>()
            .having((s) => s.alerts, 'alerts', isA<AlertsClosed>())
            .having((s) => s.failure, 'failure', isA<AlertsRefused>()),
      );
      controller.dispose();
    });

    test('a state that cannot be read is not guessed at', () async {
      notifications.failReadWith = const AlertStateUnavailable();
      final controller = controllerFor();

      await controller.load();

      expect(controller.state, isA<AlertsUnreadable>());
      controller.dispose();
    });

    test('opening the system settings re-reads afterwards', () async {
      notifications.alerts = const AlertsUnavailable();
      final controller = controllerFor();
      await controller.load();
      notifications.alerts = const AlertsClosed();

      await controller.openSystemSettings();

      expect(settingsOpened, 1);
      // Coming back from the settings page is the one moment the answer can
      // have changed without the app doing anything.
      expect(
        controller.state,
        isA<AlertsSettled>().having(
          (s) => s.alerts,
          'alerts',
          isA<AlertsClosed>(),
        ),
      );
      controller.dispose();
    });
  });

  group('the alerts section', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required bool withAlerts,
    }) async {
      await tester.pumpWidget(
        PeykTheme.wrap(
          child: SettingsScreen(
            controller: SettingsController(
              settings: _Settings(),
              actor: _courier,
            ),
            alerts: withAlerts ? controllerFor() : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Scrolls [finder] into view before tapping it.
    ///
    /// The alerts section sits below three others on a scrollable screen, so
    /// in the default 800x600 test surface it is off the bottom. `tap` only
    /// *warns* when the offset it derives would not hit the widget, so without
    /// this the taps below would land on nothing and the assertions would fail
    /// for a reason that has nothing to do with the code under test.
    Future<void> tap(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('is absent when the app supplies no controller', (
      tester,
    ) async {
      await pumpScreen(tester, withAlerts: false);

      // app_dispatcher composes no alert channel that can open, so a switch
      // there would be a control that cannot work.
      expect(find.byType(PeykSwitchRow), findsNothing);
      expect(find.text('settings.alerts.section'), findsNothing);
    });

    testWidgets('draws a switch when alerts can be turned on', (tester) async {
      await pumpScreen(tester, withAlerts: true);

      expect(find.byType(PeykSwitchRow), findsOneWidget);
      expect(find.text('settings.alerts.explanation'), findsOneWidget);
    });

    testWidgets('turning the switch on opens alerts', (tester) async {
      await pumpScreen(tester, withAlerts: true);

      await tap(tester, find.byType(Switch));

      expect(notifications.opened, ['courier-7']);
    });

    testWidgets('offers the system settings instead of a switch when the '
        'app may not ask again', (tester) async {
      notifications.alerts = const AlertsUnavailable();

      await pumpScreen(tester, withAlerts: true);

      // Two cases, two treatments. A switch here would be the button that
      // does nothing the sealed failure type exists to prevent.
      expect(find.byType(PeykSwitchRow), findsNothing);
      expect(find.text('settings.alerts.blocked'), findsOneWidget);
      expect(find.text('settings.alerts.openSettings'), findsOneWidget);
    });

    testWidgets('the system settings button opens them', (tester) async {
      notifications.alerts = const AlertsUnavailable();
      await pumpScreen(tester, withAlerts: true);

      await tap(tester, find.text('settings.alerts.openSettings'));

      expect(settingsOpened, 1);
    });

    testWidgets('says why a change did not take', (tester) async {
      await pumpScreen(tester, withAlerts: true);
      notifications.failWith = const AlertsUnreachable(detail: 'no network');

      await tap(tester, find.byType(Switch));

      expect(find.text('settings.alerts.failure.unreachable'), findsOneWidget);
    });
  });
}
