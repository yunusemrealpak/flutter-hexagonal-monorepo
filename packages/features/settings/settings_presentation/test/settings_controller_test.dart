import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_presentation/settings_presentation.dart';

/// A facade that answers whatever the test tells it to, and counts the asking.
final class _Settings implements SettingsFacade {
  final _changes = StreamController<UserPreferences>.broadcast();

  /// How many changes were actually sent.
  int writes = 0;

  /// What the next call answers.
  Result<UserPreferences, SettingsFailure> answer = const Success(
    UserPreferences.defaults(),
  );

  @override
  Future<Result<UserPreferences, SettingsFailure>> preferencesOf(
    ActorId actor,
  ) async => answer;

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseLanguage(
    ActorId actor,
    LanguageTag language,
  ) async {
    writes++;
    return answer;
  }

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  ) async {
    writes++;
    return answer;
  }

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  ) async {
    writes++;
    return answer;
  }

  @override
  Stream<UserPreferences> changes() => _changes.stream;

  Future<void> dispose() => _changes.close();
}

ActorId get _courier =>
    (ActorId.parse('courier-7') as Success<ActorId, IdentityFailure>).value;

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

  test('it starts idle and asks for nothing', () {
    expect(controller.state, isA<SettingsIdle>());
    expect(settings.writes, 0);
  });

  test('a change asked for before anything loaded is not sent', () async {
    await controller.chooseTheme(ThemePreference.dark);

    expect(settings.writes, 0);
    expect(controller.state, isA<SettingsIdle>());
  });

  test('a change asked for after a failed load is not sent', () async {
    settings.answer = const Failed(PreferencesUnavailable());
    await controller.load();

    await controller.chooseTheme(ThemePreference.dark);

    expect(settings.writes, 0);
    expect(controller.state, isA<SettingsFailed>());
  });

  test('a failed write leaves the failure on screen', () async {
    await controller.load();
    settings.answer = const Failed(PreferencesUnavailable(detail: 'locked'));

    await controller.chooseSyncPolicy(SyncPolicy.manual);

    expect(controller.state, isA<SettingsFailed>());
    expect(settings.writes, 1);
  });
}
