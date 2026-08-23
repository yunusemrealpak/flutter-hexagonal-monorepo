@Tags(['unit'])
library;

import 'package:core_navigation/core_navigation.dart';
import 'package:test/test.dart';

/// Stands in for what a `_presentation` package provides.
final class _ShipmentsCourierRoutes implements RouteModule {
  @override
  String get moduleName => 'shipments_presentation_courier';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(name: 'shipments.stops', path: '/stops'),
    RouteDefinition(name: 'shipments.detail', path: '/stops/:shipmentId'),
  ];
}

final class _IdentityRoutes implements RouteModule {
  @override
  String get moduleName => 'identity_presentation';

  @override
  List<RouteDefinition> get routes => const [
    RouteDefinition(
      name: 'identity.signIn',
      path: '/sign-in',
      requiresSession: false,
    ),
  ];
}

void main() {
  test('an app assembles its router from the modules it includes', () {
    final modules = <RouteModule>[_IdentityRoutes(), _ShipmentsCourierRoutes()];

    final names = [
      for (final module in modules)
        for (final route in module.routes) route.name,
    ];

    expect(names, [
      'identity.signIn',
      'shipments.stops',
      'shipments.detail',
    ]);
  });

  test('a destination requires a session unless it opts out', () {
    const guarded = RouteDefinition(name: 'a.b', path: '/b');
    const open = RouteDefinition(
      name: 'a.c',
      path: '/c',
      requiresSession: false,
    );

    expect(guarded.requiresSession, isTrue);
    expect(open.requiresSession, isFalse);
  });

  test(
    'a permission requirement is carried as a string, not a typed import',
    () {
      const route = RouteDefinition(
        name: 'shipments.bulkAssign',
        path: '/shipments/bulk-assign',
        requiredPermission: 'shipments.assign',
      );

      // core_navigation states the requirement; the app resolves it against the
      // PermissionChecker identity_api exposes. Neither package depends on the
      // other.
      expect(route.requiredPermission, 'shipments.assign');
    },
  );
}
