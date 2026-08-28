@Tags(['widget'])
library;

import 'package:app_harness/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_testing/identity_testing.dart';

void main() {
  late GetIt container;
  late PeykRouter router;

  setUp(() {
    container = configureHarness();
    router = buildHarnessRouter(container);
  });

  tearDown(() => container.reset());

  group('assembly', () {
    test('collects every module the app mounts', () {
      // Fourteen modules, and every route they declare. Adding a feature to
      // this app is a line in harnessModules and a line in a DI module;
      // nothing in any feature changes.
      expect(harnessModules, hasLength(14));
      expect(router.definitions, isNotEmpty);
    });

    // The cheapest possible catch for "somebody added a screen to a feature
    // and forgot to mount it". Without it the route exists, resolves, and
    // draws nothing — and the bug is found by whoever navigated there.
    //
    // Equal to the declared set rather than empty, so that a gap somebody
    // decided on reads differently from one nobody noticed. Both routes below
    // need a form this workspace has not written.
    test('every declared route is mounted or declared unmounted', () {
      expect(router.unmounted, harnessUnmountedRoutes);
    });

    test('no two features claim the same route name', () {
      final names = [
        for (final module in harnessModules)
          for (final route in module.routes) route.name,
      ];

      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('the guard', () {
    // Scenario 6 at the route level. The definition names a permission as a
    // string, because core_navigation may not see identity_api; the app is
    // where that string meets PermissionChecker.
    test('sends somebody with no session to sign-in', () {
      expect(
        router.redirectFor('shipments.courier.manifest'),
        '/sign-in',
      );
    });

    test('lets an unauthenticated route through without one', () {
      expect(router.redirectFor('identity.signIn'), isNull);
    });

    test('a name nothing declares is nobody s problem', () {
      // A router asked about a route it does not have should not decide where
      // that goes. go_router will 404 it, which is the honest answer.
      expect(router.redirectFor('nothing.here'), isNull);
    });
  });

  group('the guard, with somebody signed in', () {
    late PeykRouter guarded;

    setUp(() async {
      final session = SessionBuilder().build();
      // Replacing two registrations rather than building a second container:
      // the graph under them is the one this app composes, and a hand-built
      // stand-in would be a test of a different app.
      await container.unregister<SessionReader>();
      await container.unregister<PermissionChecker>();
      container
        ..registerSingleton<SessionReader>(_Session(session))
        ..registerSingleton<PermissionChecker>(
          const _Permissions({Permission.viewAssignedShipments}),
        );
      guarded = buildHarnessRouter(container);
    });

    test('lets them into a route their grants cover', () {
      expect(guarded.redirectFor('shipments.courier.manifest'), isNull);
    });

    // The dispatcher's board asks for viewAllShipments, which this courier
    // does not hold. They are sent home rather than shown an empty board.
    test('sends them home from a route their grants do not cover', () {
      expect(
        guarded.redirectFor('shipments.dispatcher.board'),
        isNot(isNull),
      );
    });

    // A signed-in person who lands on sign-in has nowhere to go from it: the
    // only action on that screen is one they have already taken.
    test('sends them off the sign-in screen', () {
      expect(guarded.redirectFor('identity.signIn'), isNot(isNull));
    });
  });
}

final class _Session implements SessionReader {
  const _Session(this._session);

  final Session _session;

  @override
  Session? get current => _session;

  @override
  Stream<Session?> changes() => Stream.value(_session);
}

final class _Permissions implements PermissionChecker {
  const _Permissions(this._granted);

  final Set<Permission> _granted;

  @override
  bool can(Permission permission) => _granted.contains(permission);
}
