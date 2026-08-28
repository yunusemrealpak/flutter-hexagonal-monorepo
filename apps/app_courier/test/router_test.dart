@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'support/test_platform.dart';

void main() {
  late GetIt container;
  late PeykRouter router;

  setUp(() async {
    container = await configureCourier(testPlatform());
    router = buildCourierRouter(container);
  });

  tearDown(() => container.reset());

  test('mounts twelve features, not fourteen', () {
    // The dispatcher's board and the operation's report are not in this app,
    // and neither package is a dependency of it. An app is a set of features
    // as much as a set of adapters.
    expect(courierModules, hasLength(12));
    expect(
      courierModules.map((module) => module.moduleName),
      isNot(contains('shipments.dispatcher')),
    );
    expect(
      courierModules.map((module) => module.moduleName),
      isNot(contains('reporting')),
    );
  });

  test('every declared route is mounted or declared unmounted', () {
    expect(router.unmounted, courierUnmountedRoutes);
  });

  test('no two features claim the same route name', () {
    final names = [
      for (final module in courierModules)
        for (final route in module.routes) route.name,
    ];

    expect(names.toSet(), hasLength(names.length));
  });

  group('the guard', () {
    test('sends somebody with no session to sign-in', () {
      expect(router.redirectFor('shipments.courier.manifest'), '/sign-in');
    });

    test('lets the sign-in screen through without one', () {
      expect(router.redirectFor('identity.signIn'), isNull);
    });

    // Scenario 6 at the route level, and the reason this app still has to
    // check: a courier holds viewAssignedShipments and not manageSettings, so
    // the stuck-work screen is a destination they cannot reach even though
    // their app mounts sync.
    test('a route naming a permission is guarded, not merely present', () {
      expect(
        router.definitions['sync.review']?.requiredPermission,
        'manageSettings',
      );
    });
  });
}
