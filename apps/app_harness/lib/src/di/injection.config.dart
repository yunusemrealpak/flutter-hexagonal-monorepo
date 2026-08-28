// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:core_ports/core_ports.dart' as _i398;
import 'package:delivery_api/delivery_api.dart' as _i1041;
import 'package:delivery_application/delivery_application.dart' as _i719;
import 'package:delivery_testing/delivery_testing.dart' as _i876;
import 'package:documents_api/documents_api.dart' as _i475;
import 'package:documents_core/documents_core.dart' as _i1046;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http_dio/http_dio.dart' as _i62;
import 'package:identity_api/identity_api.dart' as _i966;
import 'package:identity_application/identity_application.dart' as _i902;
import 'package:identity_testing/identity_testing.dart' as _i124;
import 'package:incidents_api/incidents_api.dart' as _i499;
import 'package:incidents_core/incidents_core.dart' as _i718;
import 'package:injectable/injectable.dart' as _i526;
import 'package:messaging_api/messaging_api.dart' as _i280;
import 'package:messaging_core/messaging_core.dart' as _i111;
import 'package:messaging_testing/messaging_testing.dart' as _i503;
import 'package:notifications_api/notifications_api.dart' as _i60;
import 'package:notifications_core/notifications_core.dart' as _i286;
import 'package:payments_api/payments_api.dart' as _i243;
import 'package:payments_application/payments_application.dart' as _i901;
import 'package:payments_testing/payments_testing.dart' as _i908;
import 'package:push_messaging/push_messaging.dart' as _i247;
import 'package:reporting_api/reporting_api.dart' as _i513;
import 'package:reporting_core/reporting_core.dart' as _i302;
import 'package:routing_api/routing_api.dart' as _i178;
import 'package:routing_application/routing_application.dart' as _i717;
import 'package:routing_testing/routing_testing.dart' as _i711;
import 'package:settings_api/settings_api.dart' as _i722;
import 'package:settings_core/settings_core.dart' as _i780;
import 'package:shipments_api/shipments_api.dart' as _i490;
import 'package:shipments_application/shipments_application.dart' as _i952;
import 'package:shipments_testing/shipments_testing.dart' as _i450;
import 'package:sync_api/sync_api.dart' as _i202;
import 'package:sync_application/sync_application.dart' as _i502;
import 'package:sync_testing/sync_testing.dart' as _i84;
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart' as _i79;
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart' as _i257;

import 'harness_delivery.dart' as _i472;
import 'harness_identity.dart' as _i569;
import 'harness_light_features.dart' as _i342;
import 'harness_payments.dart' as _i681;
import 'harness_ports.dart' as _i6;
import 'harness_routing.dart' as _i662;
import 'harness_shipments.dart' as _i649;
import 'harness_sync.dart' as _i795;
import 'harness_watchers.dart' as _i600;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final harnessDelivery = _$HarnessDelivery();
    final harnessIdentity = _$HarnessIdentity();
    final harnessLightFeatures = _$HarnessLightFeatures();
    final harnessPayments = _$HarnessPayments();
    final harnessPorts = _$HarnessPorts();
    final harnessRouting = _$HarnessRouting();
    final harnessShipments = _$HarnessShipments();
    final harnessSync = _$HarnessSync();
    gh.lazySingleton<_i876.FakeProofStore>(() => harnessDelivery.fakeProofs);
    gh.lazySingleton<_i876.FakeGeoFence>(() => harnessDelivery.fakeFence);
    gh.lazySingleton<_i1041.MediaCompressorPort>(
      () => harnessDelivery.compressor,
    );
    gh.lazySingleton<_i876.FakeDeliveryGateway>(
      () => harnessDelivery.fakeGateway,
    );
    gh.lazySingleton<_i124.FakeCredentialGateway>(
      () => harnessIdentity.fakeGateway,
    );
    gh.lazySingleton<_i966.SessionStore>(() => harnessIdentity.sessionStore);
    gh.lazySingleton<_i966.DeviceRegistry>(() => harnessIdentity.devices);
    gh.lazySingleton<_i780.ResolveLanguage>(
      () => harnessLightFeatures.resolveLanguage,
    );
    gh.lazySingleton<_i247.FakePushMessagingClient>(
      () => harnessLightFeatures.fakePush,
    );
    gh.lazySingleton<_i718.ReasonClassifier>(
      () => harnessLightFeatures.classifier,
    );
    gh.lazySingleton<_i503.InMemoryMessageStore>(
      () => harnessLightFeatures.fakeMessages,
    );
    gh.lazySingleton<_i503.FakeMessageTransport>(
      () => harnessLightFeatures.fakeMessageTransport,
    );
    gh.lazySingleton<_i908.FakePaymentsGateway>(
      () => harnessPayments.fakeGateway,
    );
    gh.lazySingleton<_i243.CashDrawerPort>(() => harnessPayments.drawer);
    gh.lazySingleton<_i243.ReceiptPrinterPort>(() => harnessPayments.receipts);
    gh.lazySingleton<_i243.SettlementStore>(() => harnessPayments.settlements);
    gh.lazySingleton<_i398.Clock>(() => harnessPorts.clock);
    gh.lazySingleton<_i398.IdGenerator>(() => harnessPorts.ids);
    gh.lazySingleton<_i398.RandomSource>(() => harnessPorts.random);
    gh.lazySingleton<_i398.Logger>(() => harnessPorts.logger);
    gh.lazySingleton<_i398.DomainEventBus>(() => harnessPorts.events);
    gh.lazySingleton<_i398.AnalyticsSink>(() => harnessPorts.analytics);
    gh.lazySingleton<_i398.NetworkStatus>(() => harnessPorts.network);
    gh.lazySingleton<_i398.PermissionRequester>(() => harnessPorts.permissions);
    gh.lazySingleton<_i398.FeatureFlagReader>(() => harnessPorts.flags);
    gh.lazySingleton<_i398.KeyValueStore>(() => harnessPorts.keyValues);
    gh.lazySingleton<_i398.SecureStore>(() => harnessPorts.secureStore);
    gh.lazySingleton<_i62.FakeHttpTransport>(() => harnessPorts.fakeTransport);
    gh.lazySingleton<_i711.FakeRouteOptimizer>(
      () => harnessRouting.fakeOptimizer,
    );
    gh.lazySingleton<_i178.TrafficDataPort>(() => harnessRouting.traffic);
    gh.lazySingleton<_i178.RouteCache>(() => harnessRouting.cache);
    gh.lazySingleton<_i711.FakeLocationStream>(
      () => harnessRouting.fakeLocation,
    );
    gh.lazySingleton<_i450.InMemoryShipmentGateway>(
      () => harnessShipments.fakeGateway,
    );
    gh.lazySingleton<_i490.ShipmentCache>(() => harnessShipments.cache);
    gh.lazySingleton<_i490.BarcodeResolverPort>(
      () => harnessShipments.barcodes,
    );
    gh.lazySingleton<_i84.InMemoryOutboxStore>(() => harnessSync.fakeOutbox);
    gh.lazySingleton<_i84.FakeCommandTransport>(
      () => harnessSync.fakeTransport,
    );
    gh.lazySingleton<_i202.ClockSkewPort>(() => harnessSync.skew);
    gh.lazySingleton<_i280.MessageTransport>(
      () => harnessLightFeatures.messageTransport(
        gh<_i503.FakeMessageTransport>(),
      ),
    );
    gh.lazySingleton<_i243.PaymentsGateway>(
      () => harnessPayments.gateway(gh<_i908.FakePaymentsGateway>()),
    );
    gh.lazySingleton<_i901.CollectionReconciler>(
      () => harnessPayments.reconciler(
        gh<_i398.DomainEventBus>(),
        gh<_i243.PaymentsGateway>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i1041.GeoFencePort>(
      () => harnessDelivery.fence(gh<_i876.FakeGeoFence>()),
    );
    gh.lazySingleton<_i966.CredentialGateway>(
      () => harnessIdentity.gateway(gh<_i124.FakeCredentialGateway>()),
    );
    gh.lazySingleton<_i202.OutboxStore>(
      () => harnessSync.outbox(gh<_i84.InMemoryOutboxStore>()),
    );
    gh.lazySingleton<_i502.EnqueueCommand>(
      () => harnessSync.enqueue(
        gh<_i202.OutboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.StartAttempt>(
      () => harnessDelivery.start(
        gh<_i1041.GeoFencePort>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i901.RefundCollection>(
      () => harnessPayments.refund(
        gh<_i243.PaymentsGateway>(),
        gh<_i243.CashDrawerPort>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i62.HttpTransport>(
      () => harnessPorts.transport(gh<_i62.FakeHttpTransport>()),
    );
    gh.lazySingleton<_i280.MessageStore>(
      () => harnessLightFeatures.messages(gh<_i503.InMemoryMessageStore>()),
    );
    gh.lazySingleton<_i111.ReadThread>(
      () => harnessLightFeatures.readThread(gh<_i280.MessageStore>()),
    );
    gh.lazySingleton<_i722.PreferencesStore>(
      () => harnessLightFeatures.preferences(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i60.InboxStore>(
      () => harnessLightFeatures.inbox(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i499.IncidentLog>(
      () => harnessLightFeatures.incidentLog(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i79.LoadCountStore>(
      () => harnessLightFeatures.counts(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i475.DocumentArchive>(
      () => harnessLightFeatures.archive(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i513.TallyStore>(
      () => harnessLightFeatures.tallies(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i202.CommandTransportPort>(
      () => harnessSync.commandTransport(gh<_i84.FakeCommandTransport>()),
    );
    gh.lazySingleton<_i178.RouteOptimizerPort>(
      () => harnessRouting.optimizer(gh<_i711.FakeRouteOptimizer>()),
    );
    gh.lazySingleton<_i502.LoadReviewQueue>(
      () => harnessSync.reviewQueue(gh<_i202.OutboxStore>()),
    );
    gh.lazySingleton<_i111.MarkThreadRead>(
      () => harnessLightFeatures.markThread(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i717.Resequence>(
      () => harnessRouting.resequence(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i717.NextStop>(
      () => harnessRouting.nextStop(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i1041.DeliveryGateway>(
      () => harnessDelivery.gateway(gh<_i876.FakeDeliveryGateway>()),
    );
    gh.lazySingleton<_i490.ShipmentGateway>(
      () => harnessShipments.gateway(gh<_i450.InMemoryShipmentGateway>()),
    );
    gh.lazySingleton<_i1041.ProofStorePort>(
      () => harnessDelivery.proofs(gh<_i876.FakeProofStore>()),
    );
    gh.lazySingleton<_i178.LocationStreamPort>(
      () => harnessRouting.location(gh<_i711.FakeLocationStream>()),
    );
    gh.lazySingleton<_i502.ResolveBlockedEntry>(
      () => harnessSync.resolveBlocked(
        gh<_i202.OutboxStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentStatusOf>(
      () => harnessPayments.statusOf(gh<_i243.PaymentsGateway>()),
    );
    gh.lazySingleton<_i718.ResolveIncident>(
      () => harnessLightFeatures.resolveIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.ReadInbox>(
      () => harnessLightFeatures.readInbox(gh<_i60.InboxStore>()),
    );
    gh.lazySingleton<_i247.PushMessagingClient>(
      () => harnessLightFeatures.push(gh<_i247.FakePushMessagingClient>()),
    );
    gh.lazySingleton<_i302.RecordOutcome>(
      () => harnessLightFeatures.recordOutcome(gh<_i513.TallyStore>()),
    );
    gh.lazySingleton<_i302.ReadRange>(
      () => harnessLightFeatures.readRange(gh<_i513.TallyStore>()),
    );
    gh.lazySingleton<_i257.CloseCount>(
      () => harnessLightFeatures.closeCount(
        gh<_i79.LoadCountStore>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i901.CloseDailySettlement>(
      () => harnessPayments.closeDay(
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.MarkAlertRead>(
      () => harnessLightFeatures.markAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i952.FindShipment>(
      () => harnessShipments.find(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i952.LoadManifest>(
      () => harnessShipments.manifest(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i111.DeliverMessage>(
      () => harnessLightFeatures.deliver(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i780.LoadPreferences>(
      () => harnessLightFeatures.loadPreferences(
        gh<_i722.PreferencesStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i286.RecordArrivingAlert>(
      () => harnessLightFeatures.recordAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i718.EscalateOverdue>(
      () => harnessLightFeatures.escalate(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i718.ReportIncident>(
      () => harnessLightFeatures.reportIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i257.RecordScan>(
      () => harnessLightFeatures.recordScan(gh<_i79.LoadCountStore>()),
    );
    gh.lazySingleton<_i257.FindOpenCount>(
      () => harnessLightFeatures.findCount(gh<_i79.LoadCountStore>()),
    );
    gh.lazySingleton<_i502.ReadSyncStatus>(
      () => harnessSync.status(
        gh<_i202.OutboxStore>(),
        gh<_i398.NetworkStatus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i902.IdentityCoordinator>(
      () => harnessIdentity.coordinator(
        gh<_i966.CredentialGateway>(),
        gh<_i966.SessionStore>(),
        gh<_i966.DeviceRegistry>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i717.PlanRoute>(
      () => harnessRouting.plan(
        gh<_i178.RouteOptimizerPort>(),
        gh<_i178.TrafficDataPort>(),
        gh<_i178.RouteCache>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i718.ShipmentFailureWatcher>(
      () => harnessLightFeatures.incidentWatcher(
        gh<_i398.DomainEventBus>(),
        gh<_i718.ReportIncident>(),
        gh<_i718.ReasonClassifier>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i475.DocumentRenderer>(
      () => harnessLightFeatures.renderer(
        gh<_i62.HttpTransport>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i257.HttpManifestSource>(
      () => harnessLightFeatures.httpManifests(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i513.ReportingFacade>(
      () => harnessLightFeatures.reporting(
        gh<_i513.TallyStore>(),
        gh<_i302.ReadRange>(),
      ),
    );
    gh.lazySingleton<_i718.ListOpenIncidents>(
      () => harnessLightFeatures.listIncidents(gh<_i499.IncidentLog>()),
    );
    gh.lazySingleton<_i111.SendMessage>(
      () => harnessLightFeatures.sendMessage(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i60.AlertChannel>(
      () => harnessLightFeatures.alerts(gh<_i247.PushMessagingClient>()),
    );
    gh.lazySingleton<_i719.AttemptReads>(
      () => harnessDelivery.reads(gh<_i1041.DeliveryGateway>()),
    );
    gh.lazySingleton<_i502.DrainOutbox>(
      () => harnessSync.drain(
        gh<_i202.OutboxStore>(),
        gh<_i202.CommandTransportPort>(),
        gh<_i202.ClockSkewPort>(),
        gh<_i398.Clock>(),
        gh<_i398.RandomSource>(),
        gh<_i398.NetworkStatus>(),
        gh<_i398.Logger>(),
        gh<_i502.ReadSyncStatus>(),
      ),
    );
    gh.lazySingleton<_i952.ResolveBarcode>(
      () => harnessShipments.resolve(
        gh<_i490.BarcodeResolverPort>(),
        gh<_i952.FindShipment>(),
      ),
    );
    gh.lazySingleton<_i302.ShipmentOutcomeWatcher>(
      () => harnessLightFeatures.reportingWatcher(
        gh<_i398.DomainEventBus>(),
        gh<_i302.RecordOutcome>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i286.OpenAlerts>(
      () => harnessLightFeatures.openAlerts(gh<_i60.AlertChannel>()),
    );
    gh.lazySingleton<_i286.CloseAlerts>(
      () => harnessLightFeatures.closeAlerts(gh<_i60.AlertChannel>()),
    );
    gh.lazySingleton<_i717.RecalculateOnDeviation>(
      () => harnessRouting.recalculate(
        gh<_i178.RouteCache>(),
        gh<_i178.LocationStreamPort>(),
        gh<_i717.PlanRoute>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i966.IdentityFacade>(
      () => harnessIdentity.identity(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.SessionReader>(
      () => harnessIdentity.sessionReader(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.PermissionChecker>(
      () => harnessIdentity.permissionChecker(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i1046.ObtainDocument>(
      () => harnessLightFeatures.obtain(
        gh<_i475.DocumentArchive>(),
        gh<_i475.DocumentRenderer>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i79.ManifestSource>(
      () => harnessLightFeatures.manifests(
        gh<_i257.HttpManifestSource>(),
        gh<_i398.KeyValueStore>(),
      ),
    );
    gh.lazySingleton<_i60.NotificationsFacade>(
      () => harnessLightFeatures.notifications(
        gh<_i286.ReadInbox>(),
        gh<_i286.MarkAlertRead>(),
        gh<_i286.RecordArrivingAlert>(),
        gh<_i286.OpenAlerts>(),
        gh<_i286.CloseAlerts>(),
        gh<_i60.AlertChannel>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i780.ApplyPreferenceChange>(
      () => harnessLightFeatures.applyPreference(
        gh<_i780.LoadPreferences>(),
        gh<_i722.PreferencesStore>(),
      ),
    );
    gh.lazySingleton<_i111.DrainQueue>(
      () => harnessLightFeatures.drainMessages(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
      ),
    );
    gh.lazySingleton<_i178.RoutingFacade>(
      () => harnessRouting.routing(
        gh<_i717.PlanRoute>(),
        gh<_i717.Resequence>(),
        gh<_i717.NextStop>(),
        gh<_i717.RecalculateOnDeviation>(),
      ),
    );
    gh.lazySingleton<_i202.SyncFacade>(
      () => harnessSync.sync(
        gh<_i502.EnqueueCommand>(),
        gh<_i502.DrainOutbox>(),
        gh<_i502.ReadSyncStatus>(),
        gh<_i502.LoadReviewQueue>(),
        gh<_i502.ResolveBlockedEntry>(),
      ),
    );
    gh.lazySingleton<_i257.StartCount>(
      () => harnessLightFeatures.startCount(
        gh<_i79.ManifestSource>(),
        gh<_i79.LoadCountStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.singleton<_i600.HarnessWatchers>(
      () => _i600.HarnessWatchers(
        reconciler: gh<_i901.CollectionReconciler>(),
        incidents: gh<_i718.ShipmentFailureWatcher>(),
        reporting: gh<_i302.ShipmentOutcomeWatcher>(),
      ),
    );
    gh.lazySingleton<_i499.IncidentsFacade>(
      () => harnessLightFeatures.incidents(
        gh<_i718.ReportIncident>(),
        gh<_i718.ListOpenIncidents>(),
        gh<_i718.EscalateOverdue>(),
        gh<_i718.ResolveIncident>(),
      ),
    );
    gh.lazySingleton<_i79.VehicleInventoryFacade>(
      () => harnessLightFeatures.vehicleInventory(
        gh<_i257.StartCount>(),
        gh<_i257.RecordScan>(),
        gh<_i257.CloseCount>(),
        gh<_i257.FindOpenCount>(),
      ),
    );
    gh.lazySingleton<_i901.CollectOnDelivery>(
      () => harnessPayments.collect(
        gh<_i243.PaymentsGateway>(),
        gh<_i243.CashDrawerPort>(),
        gh<_i243.ReceiptPrinterPort>(),
        gh<_i243.SettlementStore>(),
        gh<_i202.SyncFacade>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i280.MessagingFacade>(
      () => harnessLightFeatures.messaging(
        gh<_i111.ReadThread>(),
        gh<_i111.SendMessage>(),
        gh<_i111.MarkThreadRead>(),
        gh<_i111.DrainQueue>(),
      ),
    );
    gh.lazySingleton<_i475.DocumentsFacade>(
      () => harnessLightFeatures.documents(gh<_i1046.ObtainDocument>()),
    );
    gh.lazySingleton<_i719.FailWithReason>(
      () => harnessDelivery.fail(gh<_i202.SyncFacade>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i722.SettingsFacade>(
      () => harnessLightFeatures.settings(
        gh<_i780.LoadPreferences>(),
        gh<_i780.ApplyPreferenceChange>(),
      ),
    );
    gh.lazySingleton<_i719.CompleteWithProof>(
      () => harnessDelivery.complete(
        gh<_i1041.ProofStorePort>(),
        gh<_i1041.MediaCompressorPort>(),
        gh<_i202.SyncFacade>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i1041.DeliveryFacade>(
      () => harnessDelivery.delivery(
        gh<_i719.StartAttempt>(),
        gh<_i719.CompleteWithProof>(),
        gh<_i719.FailWithReason>(),
        gh<_i719.AttemptReads>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentsCoordinator>(
      () => harnessPayments.coordinator(
        gh<_i901.CollectOnDelivery>(),
        gh<_i901.RefundCollection>(),
        gh<_i901.CloseDailySettlement>(),
        gh<_i901.PaymentStatusOf>(),
      ),
    );
    gh.lazySingleton<_i243.PaymentStatusReader>(
      () => harnessPayments.statusReader(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i243.PaymentsFacade>(
      () => harnessPayments.payments(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i952.AdvanceShipment>(
      () => harnessShipments.advance(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
        gh<_i398.Clock>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Logger>(),
        gh<_i243.PaymentStatusReader>(),
      ),
    );
    gh.lazySingleton<_i490.ShipmentsFacade>(
      () => harnessShipments.shipments(
        gh<_i952.FindShipment>(),
        gh<_i952.ResolveBarcode>(),
        gh<_i952.LoadManifest>(),
        gh<_i952.AdvanceShipment>(),
      ),
    );
    return this;
  }
}

class _$HarnessDelivery extends _i472.HarnessDelivery {}

class _$HarnessIdentity extends _i569.HarnessIdentity {}

class _$HarnessLightFeatures extends _i342.HarnessLightFeatures {}

class _$HarnessPayments extends _i681.HarnessPayments {}

class _$HarnessPorts extends _i6.HarnessPorts {}

class _$HarnessRouting extends _i662.HarnessRouting {}

class _$HarnessShipments extends _i649.HarnessShipments {}

class _$HarnessSync extends _i795.HarnessSync {}
