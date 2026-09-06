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

  /// The changes the facade was asked for, in the order they arrived.
  final List<String> asked = [];

  /// Whether a change arrived while another was still in flight.
  ///
  /// This is what a transformer decides, stated directly. `concurrent()` makes
  /// it true; `sequential()` cannot.
  bool overlapped = false;

  /// Held open by a test that needs two calls to overlap.
  Completer<void>? gate;

  int _inFlight = 0;

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
  ) => _change('language');

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseTheme(
    ActorId actor,
    ThemePreference theme,
  ) => _change('theme');

  @override
  Future<Result<UserPreferences, SettingsFailure>> chooseSyncPolicy(
    ActorId actor,
    SyncPolicy policy,
  ) => _change('syncPolicy');

  Future<Result<UserPreferences, SettingsFailure>> _change(String what) async {
    writes++;
    asked.add(what);
    _inFlight++;
    if (_inFlight > 1) {
      overlapped = true;
    }
    if (gate case final gate?) {
      await gate.future;
    }
    _inFlight--;
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
  late SettingsBloc bloc;

  setUp(() {
    settings = _Settings();
    bloc = SettingsBloc(settings: settings, actor: _courier);
  });

  tearDown(() async {
    await bloc.close();
    await settings.dispose();
  });

  Future<void> load() async {
    bloc.add(const SettingsRequested());
    await pumpEventQueue();
  }

  test('it starts idle and asks for nothing', () {
    expect(bloc.state, isA<SettingsIdle>());
    expect(settings.writes, 0);
  });

  test('a change asked for before anything loaded is not sent', () async {
    bloc.add(const ThemeChosen(ThemePreference.dark));
    await pumpEventQueue();

    expect(settings.writes, 0);
    expect(bloc.state, isA<SettingsIdle>());
  });

  test('a change asked for after a failed load is not sent', () async {
    settings.answer = const Failed(PreferencesUnavailable());
    await load();

    bloc.add(const ThemeChosen(ThemePreference.dark));
    await pumpEventQueue();

    expect(settings.writes, 0);
    expect(bloc.state, isA<SettingsFailed>());
  });

  test('a failed write leaves the failure on screen', () async {
    await load();
    settings.answer = const Failed(PreferencesUnavailable(detail: 'locked'));

    bloc.add(const SyncPolicyChosen(SyncPolicy.manual));
    await pumpEventQueue();

    expect(bloc.state, isA<SettingsFailed>());
    expect(settings.writes, 1);
  });

  test('two changes never overlap, and arrive in the order they were '
      'made', () async {
    // What the shared `sequential()` registration buys, stated as directly as
    // it can be. `droppable()` would lose the palette; `concurrent()` would
    // let it overlap the language — and `SettingsSaving` is what disables the
    // rows, so an overlap re-enables them while a write is still out.
    await load();
    final gate = Completer<void>();
    settings.gate = gate;
    addTearDown(() => gate.isCompleted ? null : gate.complete());

    bloc
      ..add(const LanguageChosen(LanguageTag.turkish))
      ..add(const ThemeChosen(ThemePreference.dark));
    await pumpEventQueue();
    gate.complete();
    await pumpEventQueue();

    expect(settings.asked, ['language', 'theme']);
    expect(settings.overlapped, isFalse);
  });
}
