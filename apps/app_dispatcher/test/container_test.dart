import 'package:app_dispatcher/main.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
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
import 'package:reporting_api/reporting_api.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:secure_store/secure_store.dart';
import 'package:settings_api/settings_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_testing/sync_testing.dart';

import 'support/test_platform.dart';

/// The third run of the same test, over the third set of adapters.
///
/// Put the three container tests side by side and the phase's whole claim is
/// legible: the facades are the same thirteen types, the driven ports are the
/// same thirty-five contracts, and what differs is which class answers each —
/// plus which features an app composes at all.
void main() {
  late GetIt container;

  setUp(() async {
    container = await configureDispatcher(testPlatform());
  });

  tearDown(() => container.reset());

  group('every facade resolves', () {
    test('the six full-split features', () {
      expect(container<IdentityFacade>(), isNotNull);
      expect(container<ShipmentsFacade>(), isNotNull);
      // The other two of routing's three. **`RouteFollowing` is absent, and
      // that absence is the point of the phase 8 split**: it is the interface
      // whose ports read this device's position, and a desk cannot answer it
      // about a courier. Before the split this app had to bind it — and the
      // GPS behind it — to get `resequence` at all.
      expect(container<RoutePlanning>(), isNotNull);
      expect(container<RouteSupervision>(), isNotNull);
      expect(container.isRegistered<RouteFollowing>(), isFalse);
      // Two of delivery's three. `DeliveryExecution` is absent: opening an
      // attempt asks a geofence whether *this device* is at the address, and a
      // desk has no answer. Settling and reading are answered from a store, a
      // queue and a server, so both are composed here — which is also what
      // keeps `RemoteProofStore` a binding with a caller.
      expect(container<DeliverySettlement>(), isNotNull);
      expect(container<DeliveryHistory>(), isNotNull);
      expect(container.isRegistered<DeliveryExecution>(), isFalse);
      expect(container<PaymentsFacade>(), isNotNull);
      expect(container<SyncFacade>(), isNotNull);
    });

    // Five, and a different five from app_courier's six. vehicle_inventory
    // and documents are a courier's; reporting is a desk's. Neither app
    // compiles in what it does not compose.
    test('the five reduced-split features this app composes', () {
      expect(container<SettingsFacade>(), isNotNull);
      expect(container<NotificationsFacade>(), isNotNull);
      expect(container<IncidentsFacade>(), isNotNull);
      expect(container<MessagingFacade>(), isNotNull);
      expect(container<ReportingFacade>(), isNotNull);
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
  /// dispatcher column read back out of the container. It is worth asserting
  /// rather than reading, because the whole claim of the phase is that the
  /// packages below these bindings do not change — and the only way that claim
  /// can break silently is for a binding to change without anybody noticing
  /// which app they were in.
  group('the adapter table, dispatcher column', () {
    test('RouteOptimizerPort is the remote solver', () {
      // A desk is online, so the stops go to something that can do better than
      // a 2-opt sweep on a handset.
      expect(container<RouteOptimizerPort>(), isA<RemoteSolverOptimizer>());
    });

    test('CredentialGateway is single sign-on', () {
      // A dispatcher signs in at whatever desk they are sitting at.
      expect(container<CredentialGateway>(), isA<SsoCredentialGateway>());
    });

    test('OutboxStore is in memory, by choice and not by absence', () {
      // This app binds a database two registrations away. The queue is in
      // memory because a dispatcher is online and a queue that outlived a
      // session would be one nobody drains and everybody inherits.
      expect(container<OutboxStore>(), isA<InMemoryOutboxStore>());
      expect(container<PeykDatabase>(), isNotNull);
    });

    test('ProofStorePort reads evidence and keeps none', () {
      // Keeping a copy of somebody's signature on a desk is a second place it
      // exists and a second place it leaks.
      expect(container<ProofStorePort>(), isA<RemoteProofStore>());
    });

    test('PaymentsGateway is REST, as it is in the other app too', () {
      // The row where the two apps agree. A table where every row differed
      // would describe a rule; this one describes decisions.
      expect(container<PaymentsGateway>(), isA<RestPaymentsGateway>());
    });

    test('BarcodeResolverPort asks the operation', () {
      // A dispatcher scanning at the depot is looking for a parcel that may
      // not be on any manifest yet.
      expect(container<BarcodeResolverPort>(), isA<RemoteBarcodeResolver>());
    });

    test('AlertChannel declines rather than pretending', () {
      // A desk has no push client, and a stub returning Success would have
      // told a dispatcher their alerts were on and then delivered nothing.
      expect(container<AlertChannel>(), isA<DeskAlertChannel>());
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

    // The adapter takes its plugin configuration as a required argument with
    // no default, and both apps used to answer it with `const {}` — which
    // states no accessibility class and no backup behaviour and leaves both to
    // the native side. What the policy *contains* is asserted in
    // `secure_store`'s own test, on every platform; what this asserts is that
    // the app named it.
    test('the keychain is configured by name, not left to the platform', () {
      expect(
        (container<SecureStore>() as KeychainSecureStore).options,
        KeychainOptions.deviceBound,
      );
    });

    // Every REST adapter has to send through one client, or a retry policy
    // configured on the transport applies to half the product.
    test('one transport, however it is asked for', () {
      final first = container<HttpTransport>();
      expect(container<HttpTransport>(), same(first));
    });
  });
}
