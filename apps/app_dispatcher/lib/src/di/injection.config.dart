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
import 'package:delivery_application/delivery_application.dart' as _i718;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http_dio/http_dio.dart' as _i62;
import 'package:identity_api/identity_api.dart' as _i966;
import 'package:identity_application/identity_application.dart' as _i902;
import 'package:incidents_api/incidents_api.dart' as _i499;
import 'package:incidents_core/incidents_core.dart' as _i719;
import 'package:injectable/injectable.dart' as _i526;
import 'package:messaging_api/messaging_api.dart' as _i280;
import 'package:messaging_core/messaging_core.dart' as _i111;
import 'package:notifications_api/notifications_api.dart' as _i60;
import 'package:notifications_core/notifications_core.dart' as _i286;
import 'package:payments_api/payments_api.dart' as _i243;
import 'package:payments_application/payments_application.dart' as _i901;
import 'package:reporting_api/reporting_api.dart' as _i513;
import 'package:reporting_core/reporting_core.dart' as _i302;
import 'package:routing_api/routing_api.dart' as _i178;
import 'package:routing_application/routing_application.dart' as _i717;
import 'package:settings_api/settings_api.dart' as _i722;
import 'package:settings_core/settings_core.dart' as _i780;
import 'package:shipments_api/shipments_api.dart' as _i490;
import 'package:shipments_application/shipments_application.dart' as _i952;
import 'package:shipments_infrastructure/shipments_infrastructure.dart'
    as _i297;
import 'package:storage_drift/storage_drift.dart' as _i143;
import 'package:sync_api/sync_api.dart' as _i202;
import 'package:sync_application/sync_application.dart' as _i502;

import 'dispatcher_features.dart' as _i998;
import 'dispatcher_light_features.dart' as _i179;
import 'dispatcher_platform.dart' as _i973;
import 'dispatcher_ports.dart' as _i242;
import 'dispatcher_watchers.dart' as _i642;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final dispatcherFeatures = _$DispatcherFeatures();
    final dispatcherLightFeatures = _$DispatcherLightFeatures();
    final dispatcherPorts = _$DispatcherPorts();
    gh.lazySingleton<_i717.RouteChannel>(() => dispatcherFeatures.routeChannel);
    gh.lazySingleton<_i202.OutboxStore>(() => dispatcherFeatures.outbox);
    gh.lazySingleton<_i1041.MediaCompressorPort>(
      () => dispatcherFeatures.compressor,
    );
    gh.lazySingleton<_i718.DeliveryChannel>(
      () => dispatcherFeatures.deliveryChannel,
    );
    gh.lazySingleton<_i780.ResolveLanguage>(
      () => dispatcherLightFeatures.resolveLanguage,
    );
    gh.lazySingleton<_i60.AlertChannel>(() => dispatcherLightFeatures.alerts);
    gh.lazySingleton<_i719.ReasonClassifier>(
      () => dispatcherLightFeatures.classifier,
    );
    gh.lazySingleton<_i398.Clock>(() => dispatcherPorts.clock);
    gh.lazySingleton<_i398.IdGenerator>(() => dispatcherPorts.ids);
    gh.lazySingleton<_i398.RandomSource>(() => dispatcherPorts.random);
    gh.lazySingleton<_i398.DomainEventBus>(() => dispatcherPorts.events);
    gh.lazySingleton<_i398.FeatureFlagReader>(() => dispatcherPorts.flags);
    gh.lazySingleton<_i398.Logger>(
      () => dispatcherPorts.logger(gh<_i973.DispatcherPlatform>()),
    );
    gh.lazySingleton<_i398.AnalyticsSink>(
      () => dispatcherPorts.analytics(gh<_i973.DispatcherPlatform>()),
    );
    await gh.lazySingletonAsync<_i398.NetworkStatus>(
      () => dispatcherPorts.network(gh<_i973.DispatcherPlatform>()),
      preResolve: true,
    );
    gh.lazySingleton<_i143.PeykDatabase>(
      () => dispatcherPorts.database(gh<_i973.DispatcherPlatform>()),
    );
    gh.lazySingleton<_i398.SecureStore>(
      () => dispatcherPorts.secureStore(gh<_i973.DispatcherPlatform>()),
    );
    gh.lazySingleton<_i62.HttpTransport>(
      () => dispatcherPorts.transport(gh<_i973.DispatcherPlatform>()),
    );
    gh.lazySingleton<_i202.ClockSkewPort>(
      () =>
          dispatcherFeatures.skew(gh<_i62.HttpTransport>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i966.CredentialGateway>(
      () => dispatcherFeatures.gateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i297.RestShipmentGateway>(
      () => dispatcherFeatures.restShipments(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i178.RouteOptimizerPort>(
      () => dispatcherFeatures.optimizer(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i178.TrafficDataPort>(
      () => dispatcherFeatures.traffic(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i202.CommandTransportPort>(
      () => dispatcherFeatures.commandTransport(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i1041.ProofStorePort>(
      () => dispatcherFeatures.proofs(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i1041.DeliveryGateway>(
      () => dispatcherFeatures.deliveryGateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i243.PaymentsGateway>(
      () => dispatcherFeatures.paymentsGateway(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i280.MessageTransport>(
      () => dispatcherLightFeatures.messageTransport(gh<_i62.HttpTransport>()),
    );
    gh.lazySingleton<_i502.EnqueueCommand>(
      () => dispatcherFeatures.enqueue(
        gh<_i202.OutboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i966.SessionStore>(
      () => dispatcherFeatures.sessions(gh<_i398.SecureStore>()),
    );
    gh.lazySingleton<_i502.LoadReviewQueue>(
      () => dispatcherFeatures.reviewQueue(gh<_i202.OutboxStore>()),
    );
    gh.lazySingleton<_i718.AttemptReads>(
      () => dispatcherFeatures.attemptReads(gh<_i1041.DeliveryGateway>()),
    );
    gh.lazySingleton<_i490.ShipmentGateway>(
      () => dispatcherFeatures.shipmentGateway(gh<_i297.RestShipmentGateway>()),
    );
    gh.lazySingleton<_i286.OpenAlerts>(
      () => dispatcherLightFeatures.openAlerts(gh<_i60.AlertChannel>()),
    );
    gh.lazySingleton<_i286.CloseAlerts>(
      () => dispatcherLightFeatures.closeAlerts(gh<_i60.AlertChannel>()),
    );
    gh.lazySingleton<_i398.KeyValueStore>(
      () => dispatcherPorts.keyValues(
        gh<_i143.PeykDatabase>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i502.ResolveBlockedEntry>(
      () => dispatcherFeatures.resolveBlocked(
        gh<_i202.OutboxStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentStatusOf>(
      () => dispatcherFeatures.statusOf(gh<_i243.PaymentsGateway>()),
    );
    gh.lazySingleton<_i1041.DeliveryHistory>(
      () => dispatcherFeatures.deliveryHistory(
        gh<_i718.AttemptReads>(),
        gh<_i718.DeliveryChannel>(),
      ),
    );
    gh.lazySingleton<_i502.ReadSyncStatus>(
      () => dispatcherFeatures.syncStatus(
        gh<_i202.OutboxStore>(),
        gh<_i398.NetworkStatus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i490.BarcodeResolverPort>(
      () => dispatcherFeatures.barcodes(gh<_i297.RestShipmentGateway>()),
    );
    gh.lazySingleton<_i966.DeviceRegistry>(
      () => dispatcherFeatures.devices(
        gh<_i398.KeyValueStore>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i490.ShipmentCache>(
      () => dispatcherFeatures.shipmentCache(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i178.RouteCache>(
      () => dispatcherFeatures.routeCache(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.CashDrawerPort>(
      () => dispatcherFeatures.drawer(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.ReceiptPrinterPort>(
      () => dispatcherFeatures.receipts(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i243.SettlementStore>(
      () => dispatcherFeatures.settlements(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i722.PreferencesStore>(
      () => dispatcherLightFeatures.preferences(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i60.InboxStore>(
      () => dispatcherLightFeatures.inbox(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i499.IncidentLog>(
      () => dispatcherLightFeatures.incidentLog(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i280.MessageStore>(
      () => dispatcherLightFeatures.messages(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i513.TallyStore>(
      () => dispatcherLightFeatures.tallies(gh<_i398.KeyValueStore>()),
    );
    gh.lazySingleton<_i502.DrainOutbox>(
      () => dispatcherFeatures.drain(
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
      () => dispatcherLightFeatures.markThread(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i717.Resequence>(
      () => dispatcherFeatures.resequence(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i717.CurrentPlan>(
      () => dispatcherFeatures.currentPlan(gh<_i178.RouteCache>()),
    );
    gh.lazySingleton<_i398.PermissionRequester>(
      () => dispatcherPorts.permissions(
        gh<_i973.DispatcherPlatform>(),
        gh<_i398.KeyValueStore>(),
      ),
    );
    gh.lazySingleton<_i719.ResolveIncident>(
      () => dispatcherLightFeatures.resolveIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.ReadInbox>(
      () => dispatcherLightFeatures.readInbox(gh<_i60.InboxStore>()),
    );
    gh.lazySingleton<_i302.RecordOutcome>(
      () => dispatcherLightFeatures.recordOutcome(gh<_i513.TallyStore>()),
    );
    gh.lazySingleton<_i302.ReadRange>(
      () => dispatcherLightFeatures.readRange(gh<_i513.TallyStore>()),
    );
    gh.lazySingleton<_i901.CloseDailySettlement>(
      () => dispatcherFeatures.closeDay(
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i286.MarkAlertRead>(
      () => dispatcherLightFeatures.markAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.lazySingleton<_i952.FindShipment>(
      () => dispatcherFeatures.find(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i952.LoadManifest>(
      () => dispatcherFeatures.manifest(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
      ),
    );
    gh.lazySingleton<_i111.DeliverMessage>(
      () => dispatcherLightFeatures.deliver(
        gh<_i280.MessageStore>(),
        gh<_i280.MessageTransport>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i780.LoadPreferences>(
      () => dispatcherLightFeatures.loadPreferences(
        gh<_i722.PreferencesStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i286.RecordArrivingAlert>(
      () => dispatcherLightFeatures.recordAlert(
        gh<_i60.InboxStore>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i719.EscalateOverdue>(
      () => dispatcherLightFeatures.escalate(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.ReportIncident>(
      () => dispatcherLightFeatures.reportIncident(
        gh<_i499.IncidentLog>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i178.RouteSupervision>(
      () => dispatcherFeatures.routeSupervision(
        gh<_i717.Resequence>(),
        gh<_i717.RouteChannel>(),
      ),
    );
    gh.lazySingleton<_i202.SyncFacade>(
      () => dispatcherFeatures.sync(
        gh<_i502.EnqueueCommand>(),
        gh<_i502.DrainOutbox>(),
        gh<_i502.ReadSyncStatus>(),
        gh<_i502.LoadReviewQueue>(),
        gh<_i502.ResolveBlockedEntry>(),
      ),
    );
    gh.lazySingleton<_i901.CollectionReconciler>(
      () => dispatcherFeatures.reconciler(
        gh<_i398.DomainEventBus>(),
        gh<_i243.PaymentsGateway>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i902.IdentityCoordinator>(
      () => dispatcherFeatures.identity(
        gh<_i966.CredentialGateway>(),
        gh<_i966.SessionStore>(),
        gh<_i966.DeviceRegistry>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i717.PlanRoute>(
      () => dispatcherFeatures.plan(
        gh<_i178.RouteOptimizerPort>(),
        gh<_i178.TrafficDataPort>(),
        gh<_i178.RouteCache>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i719.ShipmentFailureWatcher>(
      () => dispatcherLightFeatures.incidentWatcher(
        gh<_i398.DomainEventBus>(),
        gh<_i719.ReportIncident>(),
        gh<_i719.ReasonClassifier>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i901.RefundCollection>(
      () => dispatcherFeatures.refund(
        gh<_i243.PaymentsGateway>(),
        gh<_i243.CashDrawerPort>(),
        gh<_i243.SettlementStore>(),
        gh<_i398.Clock>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i513.ReportingFacade>(
      () => dispatcherLightFeatures.reporting(
        gh<_i513.TallyStore>(),
        gh<_i302.ReadRange>(),
      ),
    );
    gh.lazySingleton<_i719.ListOpenIncidents>(
      () => dispatcherLightFeatures.listIncidents(gh<_i499.IncidentLog>()),
    );
    gh.lazySingleton<_i111.SendMessage>(
      () => dispatcherLightFeatures.sendMessage(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
        gh<_i398.Clock>(),
        gh<_i398.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i901.CollectOnDelivery>(
      () => dispatcherFeatures.collect(
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
      () => dispatcherLightFeatures.readThread(gh<_i280.MessageStore>()),
    );
    gh.lazySingleton<_i178.RoutePlanning>(
      () => dispatcherFeatures.routePlanning(
        gh<_i717.PlanRoute>(),
        gh<_i717.CurrentPlan>(),
        gh<_i717.RouteChannel>(),
      ),
    );
    gh.lazySingleton<_i952.ResolveBarcode>(
      () => dispatcherFeatures.resolve(
        gh<_i490.BarcodeResolverPort>(),
        gh<_i952.FindShipment>(),
      ),
    );
    gh.lazySingleton<_i302.ShipmentOutcomeWatcher>(
      () => dispatcherLightFeatures.reportingWatcher(
        gh<_i398.DomainEventBus>(),
        gh<_i302.RecordOutcome>(),
        gh<_i398.Logger>(),
      ),
    );
    gh.lazySingleton<_i718.FailWithReason>(
      () => dispatcherFeatures.fail(gh<_i202.SyncFacade>(), gh<_i398.Clock>()),
    );
    gh.lazySingleton<_i966.IdentityFacade>(
      () => dispatcherFeatures.identityFacade(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.SessionReader>(
      () => dispatcherFeatures.sessionReader(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i966.PermissionChecker>(
      () =>
          dispatcherFeatures.permissionChecker(gh<_i902.IdentityCoordinator>()),
    );
    gh.lazySingleton<_i60.NotificationsFacade>(
      () => dispatcherLightFeatures.notifications(
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
      () => dispatcherLightFeatures.applyPreference(
        gh<_i780.LoadPreferences>(),
        gh<_i722.PreferencesStore>(),
      ),
    );
    gh.lazySingleton<_i111.DrainQueue>(
      () => dispatcherLightFeatures.drainMessages(
        gh<_i280.MessageStore>(),
        gh<_i111.DeliverMessage>(),
      ),
    );
    gh.lazySingleton<_i718.CompleteWithProof>(
      () => dispatcherFeatures.complete(
        gh<_i1041.ProofStorePort>(),
        gh<_i1041.MediaCompressorPort>(),
        gh<_i202.SyncFacade>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Clock>(),
      ),
    );
    gh.singleton<_i642.DispatcherWatchers>(
      () => _i642.DispatcherWatchers(
        reconciler: gh<_i901.CollectionReconciler>(),
        incidents: gh<_i719.ShipmentFailureWatcher>(),
        reporting: gh<_i302.ShipmentOutcomeWatcher>(),
      ),
    );
    gh.lazySingleton<_i499.IncidentsFacade>(
      () => dispatcherLightFeatures.incidents(
        gh<_i719.ReportIncident>(),
        gh<_i719.ListOpenIncidents>(),
        gh<_i719.EscalateOverdue>(),
        gh<_i719.ResolveIncident>(),
      ),
    );
    gh.lazySingleton<_i901.PaymentsCoordinator>(
      () => dispatcherFeatures.paymentsCoordinator(
        gh<_i901.CollectOnDelivery>(),
        gh<_i901.RefundCollection>(),
        gh<_i901.CloseDailySettlement>(),
        gh<_i901.PaymentStatusOf>(),
      ),
    );
    gh.lazySingleton<_i280.MessagingFacade>(
      () => dispatcherLightFeatures.messaging(
        gh<_i111.ReadThread>(),
        gh<_i111.SendMessage>(),
        gh<_i111.MarkThreadRead>(),
        gh<_i111.DrainQueue>(),
      ),
    );
    gh.lazySingleton<_i1041.DeliverySettlement>(
      () => dispatcherFeatures.deliverySettlement(
        gh<_i718.CompleteWithProof>(),
        gh<_i718.FailWithReason>(),
        gh<_i718.DeliveryChannel>(),
      ),
    );
    gh.lazySingleton<_i722.SettingsFacade>(
      () => dispatcherLightFeatures.settings(
        gh<_i780.LoadPreferences>(),
        gh<_i780.ApplyPreferenceChange>(),
      ),
    );
    gh.lazySingleton<_i243.PaymentsFacade>(
      () => dispatcherFeatures.payments(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i243.PaymentStatusReader>(
      () => dispatcherFeatures.statusReader(gh<_i901.PaymentsCoordinator>()),
    );
    gh.lazySingleton<_i952.AdvanceShipment>(
      () => dispatcherFeatures.advance(
        gh<_i490.ShipmentGateway>(),
        gh<_i490.ShipmentCache>(),
        gh<_i398.Clock>(),
        gh<_i398.DomainEventBus>(),
        gh<_i398.Logger>(),
        gh<_i243.PaymentStatusReader>(),
      ),
    );
    gh.lazySingleton<_i490.ShipmentsFacade>(
      () => dispatcherFeatures.shipments(
        gh<_i952.FindShipment>(),
        gh<_i952.ResolveBarcode>(),
        gh<_i952.LoadManifest>(),
        gh<_i952.AdvanceShipment>(),
      ),
    );
    return this;
  }
}

class _$DispatcherFeatures extends _i998.DispatcherFeatures {}

class _$DispatcherLightFeatures extends _i179.DispatcherLightFeatures {}

class _$DispatcherPorts extends _i242.DispatcherPorts {}
