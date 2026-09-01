import 'package:app_courier/main.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:settings_api/settings_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'support/test_platform.dart';

/// The same test `app_harness` runs, over the real adapters.
///
/// It resolves in a test with no device because every adapter in `platform/*`
/// takes a plugin's platform interface through its constructor — a decision
/// made in phase 2 so that the adapters could be tested, and which turns out
/// to make the *app* testable too.
void main() {
  late GetIt container;

  setUp(() async {
    container = await configureCourier(testPlatform());
  });

  tearDown(() => container.reset());

  group('every facade resolves', () {
    test('the six full-split features', () {
      expect(container<IdentityFacade>(), isNotNull);
      expect(container<ShipmentsFacade>(), isNotNull);
      // Two of routing's three driving ports. A courier follows a route and
      // does not supervise one, so `RouteSupervision` is deliberately absent.
      expect(container<RoutePlanning>(), isNotNull);
      expect(container<RouteFollowing>(), isNotNull);
      expect(container.isRegistered<RouteSupervision>(), isFalse);
      // All three of delivery's driving ports: a courier arrives, settles and
      // reads back.
      expect(container<DeliveryExecution>(), isNotNull);
      expect(container<DeliverySettlement>(), isNotNull);
      expect(container<DeliveryHistory>(), isNotNull);
      expect(container<PaymentsFacade>(), isNotNull);
      expect(container<SyncFacade>(), isNotNull);
    });

    // Six, not seven. reporting is a dispatcher's feature and this app does
    // not depend on it — a feature nobody mounted is not compiled in.
    test('the six reduced-split features this app mounts', () {
      expect(container<SettingsFacade>(), isNotNull);
      expect(container<NotificationsFacade>(), isNotNull);
      expect(container<IncidentsFacade>(), isNotNull);
      expect(container<VehicleInventoryFacade>(), isNotNull);
      expect(container<MessagingFacade>(), isNotNull);
      expect(container<DocumentsFacade>(), isNotNull);
    });
  });

  test('every cross-cutting port resolves', () {
    expect(container<Clock>(), isNotNull);
    expect(container<IdGenerator>(), isNotNull);
    expect(container<RandomSource>(), isNotNull);
    expect(container<Logger>(), isNotNull);
    expect(container<DomainEventBus>(), isNotNull);
    expect(container<AnalyticsSink>(), isNotNull);
    expect(container<NetworkStatus>(), isNotNull);
    expect(container<PermissionRequester>(), isNotNull);
    expect(container<FeatureFlagReader>(), isNotNull);
    expect(container<KeyValueStore>(), isNotNull);
    expect(container<SecureStore>(), isNotNull);
    expect(container<HttpTransport>(), isNotNull);
    expect(container<PeykDatabase>(), isNotNull);
  });

  /// **Section 5.5, as a test.**
  ///
  /// The table names five ports where the three apps differ, and this is the
  /// courier column read back out of the container. It is worth asserting
  /// rather than reading, because the whole claim of the phase is that the
  /// packages below these bindings do not change — and the only way that claim
  /// can break silently is for a binding to change without anybody noticing
  /// which app they were in.
  group('the adapter table, courier column', () {
    test('RouteOptimizerPort is the on-device heuristic', () {
      // A courier in a tunnel still has to know where to go next.
      expect(container<RouteOptimizerPort>(), isA<LocalHeuristicOptimizer>());
    });

    test('CredentialGateway is device-bound', () {
      // A stolen password is worth nothing without the handset.
      expect(
        container<CredentialGateway>(),
        isA<DeviceBoundCredentialGateway>(),
      );
    });

    test('OutboxStore is the SQLite one', () {
      // A courier's writes have to survive the app being killed in a lift.
      expect(container<OutboxStore>(), isA<DriftOutboxStore>());
    });

    test('ProofStorePort keeps evidence on the device', () {
      // A signature captured in a basement is kept until the queue drains.
      expect(container<ProofStorePort>(), isA<LocalEncryptedProofStore>());
    });

    test('PaymentsGateway is REST, as it is in the other app too', () {
      // The row where the two apps agree. A table where every row differed
      // would describe a rule; this one describes decisions.
      expect(container<PaymentsGateway>(), isA<RestPaymentsGateway>());
    });

    test('BarcodeResolverPort answers from the cached manifest', () {
      // Not in the specification's table, and it belongs in the same list: a
      // scan on a phone has to work without a network.
      expect(container<BarcodeResolverPort>(), isA<ManifestBarcodeResolver>());
    });
  });

  group('the shape of the graph', () {
    test('shipments reads payments through a port, not the other way', () {
      expect(
        container<PaymentStatusReader>(),
        same(container<PaymentsFacade>()),
      );
    });

    test('identity answers four interfaces from one object', () {
      expect(container<SessionReader>(), same(container<IdentityFacade>()));
      expect(
        container<PermissionChecker>(),
        same(container<IdentityFacade>()),
      );
      // The fourth is the one the transport holds. A second object here would
      // be a second answer to "which session is in force", and the request
      // going out would be authorised as somebody the screens no longer show.
      expect(container<SessionTokens>(), same(container<IdentityFacade>()));
    });

    // Nothing outside identity may build the header, and nothing inside
    // identity's own use cases may know there is one. This binding is the
    // whole join, and it resolving is what stops every gateway but identity's
    // own from sending an anonymous request.
    test('the credential the transport attaches comes out of identity', () {
      expect(container<AuthorizationProvider>(), isA<BearerAuthorization>());
    });

    // Every REST adapter has to send through one client, or a retry policy
    // configured on the transport applies to half the product.
    test('one transport, however it is asked for', () {
      final first = container<HttpTransport>();
      expect(container<HttpTransport>(), same(first));
    });
  });
}
