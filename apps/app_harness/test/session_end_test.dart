@Tags(['widget'])
library;

import 'dart:async';

import 'package:app_harness/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';

/// What an ended session leaves behind, which turns out to be the interesting
/// half of the guard.
///
/// The guard attaches `?from=` to everything it refuses, so that a parcel
/// somebody followed a link to survives signing in. An ended session is
/// refused at whatever screen its owner was on — so without a second decision,
/// the next person to sign in on the same handset lands there. Interception
/// and ejection are indistinguishable to `redirectFor`; `SessionRefresh` is
/// the only place that sees the transition, and it clears the location before
/// the guard reads it.
///
/// Found by `app_courier`'s shell test and fixed in all three apps, because
/// all three assemble the same guard.
void main() {
  late GetIt container;
  late _MutableSession sessions;

  setUp(() async {
    container = configureHarness();
    sessions = _MutableSession(SessionBuilder().build());
    await container.unregister<SessionReader>();
    container.registerSingleton<SessionReader>(sessions);
  });

  tearDown(() => container.reset());

  testWidgets('an ended session leaves no location behind', (tester) async {
    final router = buildHarnessRouter(container).build();
    await tester.pumpWidget(HarnessApp(router: router));
    await tester.pumpAndSettle();

    // Somewhere that is not home, so that "went home" and "stayed put" are
    // different answers.
    router.go('/settings');
    await tester.pumpAndSettle();

    sessions.end();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/sign-in');
  });

  testWidgets('the next session starts at home, not where the last one was', (
    tester,
  ) async {
    final router = buildHarnessRouter(container).build();
    await tester.pumpWidget(HarnessApp(router: router));
    await tester.pumpAndSettle();
    router.go('/settings');
    await tester.pumpAndSettle();

    sessions
      ..end()
      ..begin(SessionBuilder().build());
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/stops');
  });
}

/// A session that can end and begin again.
///
/// A broadcast controller rather than `Stream.value`, because `SessionRefresh`
/// subscribes once and both tests push a second event through the same
/// subscription.
final class _MutableSession implements SessionReader {
  _MutableSession(this._session);

  final _changes = StreamController<Session?>.broadcast();
  Session? _session;

  @override
  Session? get current => _session;

  @override
  Stream<Session?> changes() => _changes.stream;

  void end() {
    _session = null;
    _changes.add(null);
  }

  void begin(Session session) {
    _session = session;
    _changes.add(session);
  }
}
