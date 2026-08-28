@Tags(['widget'])
library;

import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_presentation/settings_presentation.dart';

/// A `SettingsFacade` this test steers.
///
/// A fake rather than a mock: it really stores what it is given and really
/// announces it, so the tests below exercise the controller's logic instead of
/// a script of expected calls. `settings` has no `_testing` package — nothing
/// outside the feature consumes its fakes — so the stand-in lives here, which
/// is what the constitution asks for.
final class _Settings implements SettingsFacade {
  final _changes = StreamController<UserPreferences>.broadcast();

  UserPreferences _preferences = const UserPreferences.defaults();

  /// Set to fail the next call, whatever it is.
  SettingsFailure? failWith;

  @override
  Future<Result<UserPreferences, SettingsFailure>> preferencesOf(
    ActorId actor,
  ) async => _answer(_preferences);

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseLanguage(
    ActorId actor,
    LanguageTag language,
  ) async => _answer(_preferences.copyWith(language: language));

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  ) async => _answer(_preferences.copyWith(theme: theme));

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  ) async => _answer(_preferences.copyWith(syncPolicy: policy));

  @override
  Stream<UserPreferences> changes() => _changes.stream;

  /// Announces a change made somewhere else, as a second device would.
  void announce(UserPreferences preferences) => _changes.add(preferences);

  Future<void> dispose() => _changes.close();

  Result<UserPreferences, SettingsFailure> _answer(UserPreferences next) {
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      return Failed(failure);
    }
    _preferences = next;
    return Success(next);
  }
}

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

/// The tree the components need. Its default catalogue echoes keys, so every
/// assertion below is a claim about *which* string the screen asked for rather
/// than about an app's wording.
Widget _wrap(Widget child) => PeykTheme.wrap(child: child);

void main() {
  late _Settings settings;
  late SettingsController controller;

  setUp(() {
    settings = _Settings();
    controller = SettingsController(settings: settings, actor: _courier);
  });

  tearDown(() async {
    controller.dispose();
    await settings.dispose();
  });

  testWidgets('the screen shows the current choices once they arrive', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(SettingsScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(
      find.text(SettingsStrings.theme(ThemePreference.system)),
      findsOneWidget,
    );
    expect(
      find.text(SettingsStrings.syncPolicy(SyncPolicy.unmeteredOnly)),
      findsOneWidget,
    );
    expect(
      find.text(SettingsStrings.language(LanguageTag.turkish)),
      findsOneWidget,
    );
  });

  testWidgets('tapping a palette records it', (tester) async {
    await tester.pumpWidget(_wrap(SettingsScreen(controller: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(SettingsStrings.theme(ThemePreference.dark)));
    await tester.pumpAndSettle();

    expect(controller.state, isA<SettingsReady>());
    expect(
      (controller.state as SettingsReady).preferences.theme,
      ThemePreference.dark,
    );
  });

  testWidgets('a change made elsewhere reaches the screen', (tester) async {
    await tester.pumpWidget(_wrap(SettingsScreen(controller: controller)));
    await tester.pumpAndSettle();

    settings.announce(
      const UserPreferences.defaults().copyWith(syncPolicy: SyncPolicy.manual),
    );
    await tester.pumpAndSettle();

    expect(
      (controller.state as SettingsReady).preferences.syncPolicy,
      SyncPolicy.manual,
    );
  });

  testWidgets('a failure is rendered as the key an app answers', (
    tester,
  ) async {
    settings.failWith = const PreferencesUnavailable();

    await tester.pumpWidget(_wrap(SettingsScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text(SettingsStrings.failureUnavailable), findsOneWidget);
  });

  group('what SettingsStrings.all covers', () {
    // The list is derived from the enums it labels rather than written out,
    // which is what makes it stay true: adding a SyncPolicy adds a row to the
    // screen *and* a key here, so an app's coverage test fails until somebody
    // writes the sentence. A hand-written list would have let the new row ship
    // showing its own key.
    test('every option the screen can draw has a key in it', () {
      for (final theme in ThemePreference.values) {
        expect(SettingsStrings.all, contains(SettingsStrings.theme(theme)));
      }
      for (final policy in SyncPolicy.values) {
        expect(
          SettingsStrings.all,
          contains(SettingsStrings.syncPolicy(policy)),
        );
      }
      for (final tag in SettingsStrings.offeredLanguages) {
        expect(SettingsStrings.all, contains(SettingsStrings.language(tag)));
      }
    });

    test('every failure maps to a key in it', () {
      const failures = <SettingsFailure>[
        PreferencesUnavailable(),
        PreferencesCorrupted('courier-7'),
        MalformedPreference(field: 'theme', reason: 'unreadable'),
      ];

      for (final failure in failures) {
        expect(
          SettingsStrings.all,
          contains(SettingsScreen.describe(failure)),
        );
      }
    });

    test('only a malformed preference contributes an argument', () {
      expect(
        SettingsScreen.argumentsFor(
          const MalformedPreference(field: 'theme', reason: 'unreadable'),
        ),
        {'field': 'theme'},
      );
      expect(
        SettingsScreen.argumentsFor(const PreferencesUnavailable()),
        isEmpty,
      );
    });
  });
}
