// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:background_tasks/background_tasks.dart' as _i1015;
import 'package:core_ports/core_ports.dart' as _i398;
import 'package:delivery_api/delivery_api.dart' as _i1041;
import 'package:delivery_application/delivery_application.dart' as _i718;
import 'package:delivery_infrastructure/delivery_infrastructure.dart' as _i217;
import 'package:documents_api/documents_api.dart' as _i475;
import 'package:documents_core/documents_core.dart' as _i1046;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http_dio/http_dio.dart' as _i62;
import 'package:identity_api/identity_api.dart' as _i966;
import 'package:identity_application/identity_application.dart' as _i902;
import 'package:incidents_api/incidents_api.dart' as _i499;
import 'package:incidents_core/incidents_core.dart' as _i719;
import 'package:injectable/injectable.dart' as _i526;
import 'package:location_service/location_service.dart' as _i281;
import 'package:media_capture/media_capture.dart' as _i231;
import 'package:messaging_api/messaging_api.dart' as _i280;
import 'package:messaging_core/messaging_core.dart' as _i111;
import 'package:notifications_api/notifications_api.dart' as _i60;
import 'package:notifications_core/notifications_core.dart' as _i286;
import 'package:payments_api/payments_api.dart' as _i243;
import 'package:payments_application/payments_application.dart' as _i901;
import 'package:push_messaging/push_messaging.dart' as _i247;
import 'package:routing_api/routing_api.dart' as _i178;
import 'package:routing_application/routing_application.dart' as _i717;
import 'package:settings_api/settings_api.dart' as _i722;
import 'package:settings_core/settings_core.dart' as _i780;
import 'package:shipments_api/shipments_api.dart' as _i490;
import 'package:shipments_application/shipments_application.dart' as _i952;
import 'package:storage_drift/storage_drift.dart' as _i143;
import 'package:sync_api/sync_api.dart' as _i202;
import 'package:sync_application/sync_application.dart' as _i502;
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart' as _i79;
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart' as _i257;

import 'courier_features.dart' as _i407;
import 'courier_light_features.dart' as _i3;
import 'courier_platform.dart' as _i617;
import 'courier_ports.dart' as _i663;
import 'courier_watchers.dart' as _i811;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final courierFeatures = _$CourierFeatures();
    final courierLightFeatures = _$CourierLightFeatures();
    final courierPorts = _$CourierPorts();
    gh.lazySingleton<_i717.RouteChannel>(() => courierFeatures.routeChannel);
    gh.lazySingleton<_i1041.MediaCompressorPort>(
      () => courierFeatures.compressor,
    );
    gh.lazySingleton<_i718.DeliveryChannel>(
      () => courierFeatures.deliveryChannel,
    );
    gh.lazySingleton<_i178.RouteOptimizerPort>(
      () => courierFeatures.optimizer(),
    );
    gh.lazySingleton<_i780.ResolveLanguage>(
      () => courierLightFeatures.resolveLanguage,
    );
    gh.lazySingleton<_i719.ReasonClassifier>(
      () => courierLightFeatures.classifier,
    );
    gh.lazySingleton<_i398.Clock>(() => courierPorts.clock);
    gh.lazySingleton<_i398.IdGenerator>(() => courierPorts.ids);
    gh.lazySingleton<_i398.RandomSource>(() => courierPorts.random);
    gh.lazySingleton<_i398.DomainEventBus>(() => courierPorts.events);
    gh.lazySingleton<_i398.FeatureFlagReader>(() => courierPorts.flags);
    gh.lazySingleton<_i398.Logger>(
      () => courierPorts.logger(gh<_i617.CourierPlatform>()),
    );
    gh.lazySingleton<_i398.AnalyticsSink>(
      () => courierPorts.analytics(gh<_i617.CourierPlatform>()),
    );
    await gh.lazySingletonAsync<_i398.NetworkStatus>(
      () => courierPorts.network(gh<_i617.CourierPlatform>()),
      preResolve: true,
    );
    gh.lazySingleton<_i1015.BackgroundScheduler>(
      () => courierPorts.scheduler(gh<_i617.CourierPlatform>()),
    );
    gh.lazySingleton<_i143.PeykDatabase>(
      () => courierPorts.database(gh<_i617.CourierPlatform>()),
    );
    gh.lazySingleton<_i398.SecureStore>(
      () => courierPorts.secureStore(gh<_i617.CourierPlatform>()),
    );
    gh.lazySingleton<_i62.HttpTransport>(
      () => courierPorts.transport(gh<_i617.CourierPlatform>()),
    );
    gh.lazySingleton<_i202.OutboxStore>(
      () => courierFeatures.outbox(gh<_i143.PeykDatabase>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i398.KeyValueStore>(
      () => courierPorts.keyValues(gh<_i143.PeykDatabase>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i502.ResolveBlockedEntry>(
      () => courierFeatures.resolveBlocked(
        gh<_i202.OutboxStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i502.ReadSyncStatus>(
      () => courierFeatures.syncStatus(
        gh<_i202.OutboxStore>(),
        gh<_i398.NetworkStatus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i202.ClockSkewPort>(
      () => courierFeatures.skew(gh<_i62.HttpTransport>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i475.DocumentRenderer>(
      () => courierLightFeatures.renderer(
        gh<_i62.HttpTransport>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i966.CredentialGateway>(
      () => courierFeatures.gateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i490.ShipmentGateway>(
      () => courierFeatures.shipmentGateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i178.TrafficDataPort>(
      () => courierFeatures.traffic(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i202.CommandTransportPort>(
      () => courierFeatures.commandTransport(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i1041.DeliveryGateway>(
      () => courierFeatures.deliveryGateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i243.PaymentsGateway>(
      () => courierFeatures.paymentsGateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i257.HttpManifestSource>(
      () => courierLightFeatures.httpManifests(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i280.MessageTransport>(
      () => courierLightFeatures.messageTransport(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i502.EnqueueCommand>(
      () => courierFeatures.enqueue(
        gh<_i202.OutboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i966.DeviceRegistry>(
      () => courierFeatures.devices(
        gh<_i398.KeyValueStore>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i490.ShipmentCache>(
      () => courierFeatures.shipmentCache(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i178.RouteCache>(
      () => courierFeatures.routeCache(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i1041.ProofStorePort>(
      () => courierFeatures.proofs(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.CashDrawerPort>(
      () => courierFeatures.drawer(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.ReceiptPrinterPort>(
      () => courierFeatures.receipts(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.SettlementStore>(
      () => courierFeatures.settlements(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i722.PreferencesStore>(
      () => courierLightFeatures.preferences(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i60.InboxStore>(
      () => courierLightFeatures.inbox(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i60.AlertRegistry>(
      () => courierLightFeatures.alertRegistry(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i499.IncidentLog>(
      () => courierLightFeatures.incidentLog(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i79.LoadCountStore>(
      () => courierLightFeatures.counts(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i280.MessageStore>(
      () => courierLightFeatures.messages(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i475.DocumentArchive>(
      () => courierLightFeatures.archive(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i966.SessionStore>(
      () => courierFeatures.sessions(gh<_i398.SecureStore>()),
    );
    gh.lazySingleton<_i502.LoadReviewQueue>(
      () => courierFeatures.reviewQueue(gh<_i202.OutboxStore>()),
    );
    gh.lazySingleton<_i718.AttemptReads>(
      () => courierFeatures.attemptReads(gh<_i1041.DeliveryGateway>()),
    );
    gh.lazySingleton<_i502.DrainOutbox>(
      () => courierFeatures.drain(
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
    gh.lazySingleton<_i111.MarkThreadRead>(
      () => courierLightFeatures.markThread(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i490.BarcodeResolverPort>(
      () => courierFeatures.barcodes(gh<_i490.ShipmentCache>()),
    );
    gh.lazySingleton<_i717.NextStop>(
      () => courierFeatures.nextStop(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i717.CurrentPlan>(
      () => courierFeatures.currentPlan(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i398.PermissionRequester>(
      () => courierPorts.permissions(
        gh<_i617.CourierPlatform>(),
        gh<_i398.KeyValueStore>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentStatusOf>(
      () => courierFeatures.statusOf(gh<_i243.PaymentsGateway>()),
    );
    gh.lazySingleton<_i1046.ObtainDocument>(
      () => courierLightFeatures.obtain(
        gh<_i475.DocumentArchive>(),
        gh<_i475.DocumentRenderer>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.ResolveIncident>(
      () => courierLightFeatures.resolveIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.ReadInbox>(
      () => courierLightFeatures.readInbox(gh<_i60.InboxStore>()),
    );
    gh.lazySingleton<_i79.ManifestSource>(
      () => courierLightFeatures.manifests(
        gh<_i257.HttpManifestSource>(),
        gh<_i398.KeyValueStore>(),
      ),
    );
    gh.lazySingleton<_i257.CloseCount>(
      () => courierLightFeatures.closeCount(
        gh<_i79.LoadCountStore>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i901.CloseDailySettlement>(
      () => courierFeatures.closeDay(
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.MarkAlertRead>(
      () => courierLightFeatures.markAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i952.FindShipment>(
      () => courierFeatures.find(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i952.LoadManifest>(
      () => courierFeatures.manifest(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i111.DeliverMessage>(
      () => courierLightFeatures.deliver(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i780.LoadPreferences>(
      () => courierLightFeatures.loadPreferences(
        gh<_i722.PreferencesStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i286.RecordArrivingAlert>(
      () => courierLightFeatures.recordAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i231.MediaCapture>(
      () => courierFeatures.cameraCapture(
        gh<_i617.CourierPlatform>(),
        gh<_i398.PermissionRequester>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i247.PushMessagingClient>(
      () => courierLightFeatures.push(
        gh<_i617.CourierPlatform>(),
        gh<_i398.PermissionRequester>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i719.EscalateOverdue>(
      () => courierLightFeatures.escalate(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.ReportIncident>(
      () => courierLightFeatures.reportIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i257.RecordScan>(
      () => courierLightFeatures.recordScan(gh<_i79.LoadCountStore>()),
    );
    gh.lazySingleton<_i257.FindOpenCount>(
      () => courierLightFeatures.findCount(gh<_i79.LoadCountStore>()),
    );
    gh.lazySingleton<_i1041.DeliveryHistory>(
      () => courierFeatures.deliveryHistory(
        gh<_i718.AttemptReads>(),
        gh<_i718.DeliveryChannel>(),
      ),
    );
    gh.lazySingleton<_i202.SyncFacade>(
      () => courierFeatures.sync(
        gh<_i502.EnqueueCommand>(),
        gh<_i502.DrainOutbox>(),
        gh<_i502.ReadSyncStatus>(),
        gh<_i502.LoadReviewQueue>(),
        gh<_i502.ResolveBlockedEntry>(),
      ),
    );
    gh.lazySingleton<_i901.CollectionReconciler>(
      () => courierFeatures.reconciler(
        gh<_i398.DomainEventBus>(),
        gh<_i243.PaymentsGateway>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i902.IdentityCoordinator>(
      () => courierFeatures.identity(
        gh<_i966.CredentialGateway>(),
        gh<_i966.SessionStore>(),
        gh<_i966.DeviceRegistry>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i257.StartCount>(
      () => courierLightFeatures.startCount(
        gh<_i79.ManifestSource>(),
        gh<_i79.LoadCountStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i717.PlanRoute>(
      () => courierFeatures.plan(
        gh<_i178.RouteOptimizerPort>(),
        gh<_i178.TrafficDataPort>(),
        gh<_i178.RouteCache>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i286.ReadAlertState>(
      () => courierLightFeatures.readAlertState(
        gh<_i60.AlertRegistry>(),
        gh<_i398.PermissionRequester>(),
      ),
    );
    gh.lazySingleton<_i719.ShipmentFailureWatcher>(
      () => courierLightFeatures.incidentWatcher(
        gh<_i398.DomainEventBus>(),
        gh<_i719.ReportIncident>(),
        gh<_i719.ReasonClassifier>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i281.LocationSource>(
      () => courierFeatures.locationSource(
        gh<_i617.CourierPlatform>(),
        gh<_i398.PermissionRequester>(),
      ),
    );
    gh.lazySingleton<_i178.LocationStreamPort>(
      () => courierFeatures.locationStream(gh<_i281.LocationSource>()),
    );
    gh.lazySingleton<_i1041.GeoFencePort>(
      () => courierFeatures.fence(
        gh<_i62.HttpTransport>(),
        gh<_i281.LocationSource>(),
      ),
    );
    gh.lazySingleton<_i718.StartAttempt>(
      () => courierFeatures.start(
        gh<_i1041.GeoFencePort>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i901.RefundCollection>(
      () => courierFeatures.refund(
        gh<_i243.PaymentsGateway>(),
        gh<_i243.CashDrawerPort>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i79.VehicleInventoryFacade>(
      () => courierLightFeatures.vehicleInventory(
        gh<_i257.StartCount>(),
        gh<_i257.RecordScan>(),
        gh<_i257.CloseCount>(),
        gh<_i257.FindOpenCount>(),
      ),
    );
    gh.lazySingleton<_i217.CameraProofSource>(
      () => courierFeatures.cameraProof(
        gh<_i231.MediaCapture>(),
        gh<_i1041.MediaCompressorPort>(),
        gh<_i398.KeyValueStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.ListOpenIncidents>(
      () => courierLightFeatures.listIncidents(gh<_i499.IncidentLog>()),
    );
    gh.lazySingleton<_i111.SendMessage>(
      () => courierLightFeatures.sendMessage(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i901.CollectOnDelivery>(
      () => courierFeatures.collect(
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
    gh.lazySingleton<_i111.ReadThread>(
      () => courierLightFeatures.readThread(gh<_i280.MessageStore>()),
    );
    gh.lazySingleton<_i60.AlertChannel>(
      () => courierLightFeatures.alerts(gh<_i247.PushMessagingClient>()),
    );
    gh.lazySingleton<_i178.RoutePlanning>(
      () => courierFeatures.routePlanning(
        gh<_i717.PlanRoute>(),
        gh<_i717.CurrentPlan>(),
        gh<_i717.RouteChannel>(),
      ),
    );
    gh.lazySingleton<_i475.DocumentsFacade>(
      () => courierLightFeatures.documents(gh<_i1046.ObtainDocument>()),
    );
    gh.lazySingleton<_i1041.DeliveryExecution>(
      () => courierFeatures.deliveryExecution(
        gh<_i718.StartAttempt>(),
        gh<_i718.DeliveryChannel>(),
      ),
    );
    gh.lazySingleton<_i952.ResolveBarcode>(
      () => courierFeatures.resolve(
        gh<_i490.BarcodeResolverPort>(),
        gh<_i952.FindShipment>(),
      ),
    );
    gh.lazySingleton<_i717.RecalculateOnDeviation>(
      () => courierFeatures.recalculate(
        gh<_i178.RouteCache>(),
        gh<_i178.LocationStreamPort>(),
        gh<_i717.PlanRoute>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i718.FailWithReason>(
      () => courierFeatures.fail(gh<_i202.SyncFacade>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i966.IdentityFacade>(
      () => courierFeatures.identityFacade(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.SessionReader>(
      () => courierFeatures.sessionReader(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.PermissionChecker>(
      () => courierFeatures.permissionChecker(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.SessionTokens>(
      () => courierFeatures.sessionTokens(gh<_i902.IdentityCoordinator>()),
    );
    gh.singleton<_i811.CourierWatchers>(
      () => _i811.CourierWatchers(
        reconciler: gh<_i901.CollectionReconciler>(),
        incidents: gh<_i719.ShipmentFailureWatcher>(),
      ),
    );
    gh.lazySingleton<_i780.ApplyPreferenceChange>(
      () => courierLightFeatures.applyPreference(
        gh<_i780.LoadPreferences>(),
        gh<_i722.PreferencesStore>(),
      ),
    );
    gh.lazySingleton<_i111.DrainQueue>(
      () => courierLightFeatures.drainMessages(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
      ),
    );
    gh.lazySingleton<_i718.CompleteWithProof>(
      () => courierFeatures.complete(
        gh<_i1041.ProofStorePort>(),
        gh<_i1041.MediaCompressorPort>(),
        gh<_i202.SyncFacade>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i62.AuthorizationProvider>(
      () => courierFeatures.authorization(
        gh<_i966.SessionTokens>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i499.IncidentsFacade>(
      () => courierLightFeatures.incidents(
        gh<_i719.ReportIncident>(),
        gh<_i719.ListOpenIncidents>(),
        gh<_i719.EscalateOverdue>(),
        gh<_i719.ResolveIncident>(),
      ),
    );
    gh.lazySingleton<_i178.RouteFollowing>(
      () => courierFeatures.routeFollowing(
        gh<_i717.NextStop>(),
        gh<_i717.RecalculateOnDeviation>(),
        gh<_i717.RouteChannel>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentsCoordinator>(
      () => courierFeatures.paymentsCoordinator(
        gh<_i901.CollectOnDelivery>(),
        gh<_i901.RefundCollection>(),
        gh<_i901.CloseDailySettlement>(),
        gh<_i901.PaymentStatusOf>(),
      ),
    );
    gh.lazySingleton<_i286.OpenAlerts>(
      () => courierLightFeatures.openAlerts(
        gh<_i60.AlertChannel>(),
        gh<_i60.AlertRegistry>(),
      ),
    );
    gh.lazySingleton<_i286.CloseAlerts>(
      () => courierLightFeatures.closeAlerts(
        gh<_i60.AlertChannel>(),
        gh<_i60.AlertRegistry>(),
      ),
    );
    gh.lazySingleton<_i280.MessagingFacade>(
      () => courierLightFeatures.messaging(
        gh<_i111.ReadThread>(),
        gh<_i111.SendMessage>(),
        gh<_i111.MarkThreadRead>(),
        gh<_i111.DrainQueue>(),
      ),
    );
    gh.lazySingleton<_i1041.DeliverySettlement>(
      () => courierFeatures.deliverySettlement(
        gh<_i718.CompleteWithProof>(),
        gh<_i718.FailWithReason>(),
        gh<_i718.DeliveryChannel>(),
      ),
    );
    gh.lazySingleton<_i722.SettingsFacade>(
      () => courierLightFeatures.settings(
        gh<_i780.LoadPreferences>(),
        gh<_i780.ApplyPreferenceChange>(),
      ),
    );
    gh.lazySingleton<_i60.NotificationsFacade>(
      () => courierLightFeatures.notifications(
        gh<_i286.ReadInbox>(),
        gh<_i286.MarkAlertRead>(),
        gh<_i286.RecordArrivingAlert>(),
        gh<_i286.OpenAlerts>(),
        gh<_i286.CloseAlerts>(),
        gh<_i286.ReadAlertState>(),
        gh<_i60.AlertChannel>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i243.PaymentsFacade>(
      () => courierFeatures.payments(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i243.PaymentStatusReader>(
      () => courierFeatures.statusReader(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i952.AdvanceShipment>(
      () => courierFeatures.advance(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
        gh<_i398.Clock>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Logger>(),
        gh<_i243.PaymentStatusReader>(),
      ),
    );
    gh.lazySingleton<_i490.ShipmentsFacade>(
      () => courierFeatures.shipments(
        gh<_i952.FindShipment>(),
        gh<_i952.ResolveBarcode>(),
        gh<_i952.LoadManifest>(),
        gh<_i952.AdvanceShipment>(),
      ),
    );
    return this;
  }
}

class _$CourierFeatures extends _i407.CourierFeatures {}

class _$CourierLightFeatures extends _i3.CourierLightFeatures {}

class _$CourierPorts extends _i663.CourierPorts {}
