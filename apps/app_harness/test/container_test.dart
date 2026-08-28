import 'package:app_harness/main.dart';
import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:documents_api/documents_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:routing_api/routing_api.dart';
import 'package:settings_api/settings_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:sync_api/sync_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// The acceptance test phase 7 is measured by: does every port resolve.
///
/// It is worth being clear about what this catches, because "the container
/// works" sounds like a tautology. `injectable` builds a graph at code
/// generation time and hands back a container that constructs lazily — so a
/// registration that asks for something nobody provides compiles, generates,
/// and throws the first time a screen is opened. In an app with 128
/// registrations that is a runtime error found by whoever navigated there.
///
/// Resolving every facade forces the whole graph. A missing adapter fails
/// here, in a test that takes milliseconds, with the name of the type nobody
/// registered.
void main() {
  late GetIt container;

  setUp(() {
    // A fresh container per test, not GetIt.instance. Two tests sharing a
    // container share a FakeHttpTransport's queued responses, and the failure
    // looks like a bug in an adapter.
    container = configureHarness();
  });

  tearDown(() => container.reset());

  group('every facade resolves', () {
    // Thirteen features, thirteen facades. Each one pulls its use cases, and
    // each use case pulls its ports, so this list reaches the whole graph.
    test('the six full-split features', () {
      expect(container<IdentityFacade>(), isNotNull);
      expect(container<ShipmentsFacade>(), isNotNull);
      // All three, because this app composes everything.
      expect(container<RoutePlanning>(), isNotNull);
      expect(container<RouteSupervision>(), isNotNull);
      expect(container<RouteFollowing>(), isNotNull);
      expect(container<DeliveryExecution>(), isNotNull);
      expect(container<DeliverySettlement>(), isNotNull);
      expect(container<DeliveryHistory>(), isNotNull);
      expect(container<PaymentsFacade>(), isNotNull);
      expect(container<SyncFacade>(), isNotNull);
    });

    test('the seven reduced-split features', () {
      expect(container<SettingsFacade>(), isNotNull);
      expect(container<NotificationsFacade>(), isNotNull);
      expect(container<IncidentsFacade>(), isNotNull);
      expect(container<VehicleInventoryFacade>(), isNotNull);
      expect(container<MessagingFacade>(), isNotNull);
      expect(container<DocumentsFacade>(), isNotNull);
      expect(container<ReportingFacade>(), isNotNull);
    });
  });

  group('every cross-cutting port resolves', () {
    test('core_ports', () {
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
    });
  });

  group('every driven port resolves', () {
    // The ports a use case takes. Resolving a facade already reaches these,
    // but naming them makes a failure say *which* adapter is missing rather
    // than which facade could not be built.
    test('identity', () {
      expect(container<CredentialGateway>(), isNotNull);
      expect(container<SessionStore>(), isNotNull);
      expect(container<DeviceRegistry>(), isNotNull);
    });

    test('shipments', () {
      expect(container<ShipmentGateway>(), isNotNull);
      expect(container<ShipmentCache>(), isNotNull);
      expect(container<BarcodeResolverPort>(), isNotNull);
    });

    test('routing', () {
      expect(container<RouteOptimizerPort>(), isNotNull);
      expect(container<TrafficDataPort>(), isNotNull);
      expect(container<RouteCache>(), isNotNull);
      expect(container<LocationStreamPort>(), isNotNull);
    });

    test('delivery', () {
      expect(container<ProofStorePort>(), isNotNull);
      expect(container<GeoFencePort>(), isNotNull);
      expect(container<MediaCompressorPort>(), isNotNull);
      expect(container<DeliveryGateway>(), isNotNull);
    });

    test('payments', () {
      expect(container<PaymentsGateway>(), isNotNull);
      expect(container<CashDrawerPort>(), isNotNull);
      expect(container<ReceiptPrinterPort>(), isNotNull);
      expect(container<SettlementStore>(), isNotNull);
    });

    test('sync', () {
      expect(container<OutboxStore>(), isNotNull);
      expect(container<CommandTransportPort>(), isNotNull);
      expect(container<ClockSkewPort>(), isNotNull);
    });

    test('the light features', () {
      expect(container<PreferencesStore>(), isNotNull);
      expect(container<AlertChannel>(), isNotNull);
      expect(container<InboxStore>(), isNotNull);
      expect(container<IncidentLog>(), isNotNull);
      expect(container<ManifestSource>(), isNotNull);
      expect(container<LoadCountStore>(), isNotNull);
      expect(container<MessageStore>(), isNotNull);
      expect(container<MessageTransport>(), isNotNull);
      expect(container<DocumentArchive>(), isNotNull);
      expect(container<DocumentRenderer>(), isNotNull);
      expect(container<TallyStore>(), isNotNull);
    });
  });

  group('the shape of the graph', () {
    // Scenario 1's proof, and the reason it is worth asserting rather than
    // reading: shipments' state machine asks payments a question, and payments
    // never asks shipments anything. The two coordinators are separate
    // objects; what joins them is one contract.
    test('shipments reads payments through a port, not the other way', () {
      expect(container<PaymentStatusReader>(), isNotNull);
      expect(
        container<PaymentStatusReader>(),
        same(container<PaymentsFacade>()),
        reason: 'one coordinator, two views of it',
      );
    });

    // The identity coordinator answers three interfaces, and a screen that
    // got its permissions from a different object than its session would show
    // actions for somebody who is not signed in.
    test('identity answers three interfaces from one object', () {
      expect(container<SessionReader>(), same(container<IdentityFacade>()));
      expect(
        container<PermissionChecker>(),
        same(container<IdentityFacade>()),
      );
    });

    // Every adapter that takes a transport must take the *same* one, or a
    // test that queues a response sees it consumed by whichever adapter it did
    // not mean.
    test('one transport, however it is asked for', () {
      expect(container<HttpTransport>(), same(container<FakeHttpTransport>()));
    });
  });
}
