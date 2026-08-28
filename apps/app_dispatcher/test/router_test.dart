@Tags(['widget'])
library;

import 'package:app_dispatcher/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'support/test_platform.dart';

void main() {
  late GetIt container;
  late PeykRouter router;

  setUp(() async {
    container = await configureDispatcher(testPlatform());
    router = buildDispatcherRouter(container);
  });

  tearDown(() => container.reset());

  test('mounts ten features, and only six overlap with the courier app', () {
    // A van is counted by whoever stands next to it and a waybill belongs to
    // whoever carries the parcel, so neither is here. The board and the
    // report are, and neither is in app_courier.
    final mounted = dispatcherModules
        .map((module) => module.moduleName)
        .toSet();

    expect(dispatcherModules, hasLength(10));
    expect(mounted, contains('shipments.dispatcher'));
    expect(mounted, contains('reporting'));
    expect(mounted, isNot(contains('shipments.courier')));
    expect(mounted, isNot(contains('vehicle_inventory')));
    expect(mounted, isNot(contains('documents')));
  });

  // The one that is worth a test of its own: this app *composes* delivery —
  // DeliveryFacade resolves, and RemoteProofStore is row 4 of the table — and
  // mounts none of its destinations. A dispatcher reads an attempt and never
  // stands at a door. A feature is a set of use cases and a set of screens,
  // and an app can want one without the other.
  test('composes delivery and mounts none of it', () {
    expect(
      dispatcherModules.map((module) => module.moduleName),
      isNot(contains('delivery')),
    );
  });

  test('every declared route is mounted or declared unmounted', () {
    expect(router.unmounted, dispatcherUnmountedRoutes);
  });

  test('no two features claim the same route name', () {
    final names = [
      for (final module in dispatcherModules)
        for (final route in module.routes) route.name,
    ];

    expect(names.toSet(), hasLength(names.length));
  });

  group('the guard', () {
    test('sends somebody with no session to sign-in', () {
      expect(router.redirectFor('shipments.dispatcher.board'), '/sign-in');
    });

    test('lets the sign-in screen through without one', () {
      expect(router.redirectFor('identity.signIn'), isNull);
    });

    // Scenario 6 at the route level. The permission crosses as a string
    // because core_navigation may not see identity_api, and the app is where
    // that string meets PermissionChecker.
    test('a route naming a permission is guarded, not merely present', () {
      expect(
        router.definitions['sync.review']?.requiredPermission,
        'manageSettings',
      );
    });
  });
}
