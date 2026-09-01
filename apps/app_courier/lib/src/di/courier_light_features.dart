import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_core/documents_core.dart';
import 'package:http_dio/http_dio.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_core/incidents_core.dart';
import 'package:injectable/injectable.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_core/messaging_core.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_core/notifications_core.dart';
import 'package:push_messaging/push_messaging.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart';

import 'courier_platform.dart';

/// The reduced-split features this app mounts, on their real adapters.
///
/// **Six, not seven.** `reporting` is a dispatcher's screen — a courier has no
/// use for the operation's daily figures and no permission to read them — so
/// it is absent from this app entirely. That absence is the point of scenario
/// 5 at the feature level rather than the port level: an app is a set of
/// features as much as a set of adapters, and a feature nobody mounted costs
/// nothing.
///
/// Every registration here is the same *class* `app_harness` registers. What
/// changed is one layer below: `KeyValuePreferencesStore` writes into SQLite
/// here and into a map there, because `KeyValueStore` resolves differently.
/// A reduced-split feature's adapter is written against a driven port for
/// exactly this reason.
@module
abstract class CourierLightFeatures {
  // -- settings ------------------------------------------------------------

  /// Preferences, in the key-value store.
  @lazySingleton
  PreferencesStore preferences(KeyValueStore store) =>
      KeyValuePreferencesStore(store: store);

  /// Reading them.
  @lazySingleton
  LoadPreferences loadPreferences(PreferencesStore store, Logger logger) =>
      LoadPreferences(store: store, logger: logger);

  /// Changing one.
  @lazySingleton
  ApplyPreferenceChange applyPreference(
    LoadPreferences load,
    PreferencesStore store,
  ) => ApplyPreferenceChange(load: load, store: store);

  /// The one implementation of `SettingsFacade`.
  @lazySingleton
  SettingsFacade settings(
    LoadPreferences load,
    ApplyPreferenceChange apply,
  ) => SettingsCoordinator(load: load, apply: apply);

  /// Falling back when a stored language has no bundle behind it.
  ///
  /// The harness offers Turkish only, which is what `design_system` ships and
  /// what this app's own screens ask for. An app that offered more would pass
  /// more, and the use case would not change.
  /// Not `const`: `LanguageTag` overrides `==`, and a constant set may not
  /// hold a value that does. That is the analyzer protecting the difference
  /// between identity and equality inside a canonicalised literal, and it is
  /// the right call — a value object exists precisely so that two instances
  /// with the same content are the same tag.
  @lazySingleton
  ResolveLanguage get resolveLanguage => ResolveLanguage(
    available: {LanguageTag.turkish},
    fallback: LanguageTag.turkish,
  );

  // -- notifications -------------------------------------------------------

  /// Firebase, through its platform interface.
  ///
  /// The interface rather than the plugin's singleton, which is what lets
  /// this app's container be built in a test without a Firebase project. It
  /// is the same decision every adapter in `platform/*` made in phase 2, and
  /// `CourierPlatform` is where it pays off.
  @lazySingleton
  PushMessagingClient push(
    CourierPlatform platform,
    PermissionRequester permissions,
    Clock clock,
  ) => FirebasePushMessagingClient(platform.push, permissions, clock);

  /// The alert channel over it.
  ///
  /// `notifications_core` may see `platform/*` and `notifications_application`
  /// could not — the one row in section 2 that carries both a platform edge
  /// and a foreign `_api`, and the reason phase 6 gave this feature a reduced
  /// split at all.
  @lazySingleton
  AlertChannel alerts(PushMessagingClient client) =>
      PushAlertChannel(client: client);

  /// The inbox.
  @lazySingleton
  InboxStore inbox(KeyValueStore store) => KeyValueInboxStore(store: store);

  /// Reading it.
  @lazySingleton
  ReadInbox readInbox(InboxStore inbox) => ReadInbox(inbox: inbox);

  /// Marking one read.
  @lazySingleton
  MarkAlertRead markAlert(InboxStore inbox, Clock clock) =>
      MarkAlertRead(inbox: inbox, clock: clock);

  /// Taking an arriving alert.
  @lazySingleton
  RecordArrivingAlert recordAlert(
    InboxStore inbox,
    Clock clock,
    IdGenerator ids,
  ) => RecordArrivingAlert(inbox: inbox, clock: clock, ids: ids);

  /// What this device remembers about having opened alerts.
  ///
  /// Firebase will not say which topics a device is subscribed to, so the one
  /// fact a settings switch needs is one the product keeps itself.
  @lazySingleton
  AlertRegistry alertRegistry(KeyValueStore store) =>
      KeyValueAlertRegistry(store: store);

  /// Turning alerts on.
  @lazySingleton
  OpenAlerts openAlerts(AlertChannel channel, AlertRegistry registry) =>
      OpenAlerts(channel: channel, registry: registry);

  /// Turning them off.
  @lazySingleton
  CloseAlerts closeAlerts(AlertChannel channel, AlertRegistry registry) =>
      CloseAlerts(channel: channel, registry: registry);

  /// Saying whether they are on, which is the permission and the record read
  /// together.
  @lazySingleton
  ReadAlertState readAlertState(
    AlertRegistry registry,
    PermissionRequester permissions,
  ) => ReadAlertState(registry: registry, permissions: permissions);

  /// The one implementation of `NotificationsFacade`.
  @lazySingleton
  NotificationsFacade notifications(
    ReadInbox read,
    MarkAlertRead mark,
    RecordArrivingAlert record,
    OpenAlerts open,
    CloseAlerts close,
    ReadAlertState state,
    AlertChannel channel,
    Logger logger,
  ) => NotificationsCoordinator(
    read: read,
    mark: mark,
    record: record,
    open: open,
    close: close,
    state: state,
    channel: channel,
    logger: logger,
  );

  // -- incidents -----------------------------------------------------------

  /// The log.
  @lazySingleton
  IncidentLog incidentLog(KeyValueStore store) =>
      KeyValueIncidentLog(store: store);

  /// Recording one.
  @lazySingleton
  ReportIncident reportIncident(
    IncidentLog log,
    Clock clock,
    IdGenerator ids,
  ) => ReportIncident(log: log, clock: clock, ids: ids);

  /// Reading the open ones.
  @lazySingleton
  ListOpenIncidents listIncidents(IncidentLog log) =>
      ListOpenIncidents(log: log);

  /// Raising the ones nobody has answered.
  @lazySingleton
  EscalateOverdue escalate(IncidentLog log, Clock clock, Logger logger) =>
      EscalateOverdue(
        log: log,
        clock: clock,
        policy: const EscalationPolicy.standard(),
        logger: logger,
      );

  /// Closing one.
  @lazySingleton
  ResolveIncident resolveIncident(IncidentLog log, Clock clock) =>
      ResolveIncident(log: log, clock: clock);

  /// Turning a delivery's words into a category incidents owns.
  @lazySingleton
  ReasonClassifier get classifier => const ReasonClassifier();

  /// Scenario 2 again, in a light feature: a watcher on `ShipmentFailed`.
  ///
  /// Registered but not started — `HarnessWatchers` does that, and holds the
  /// subscription this one hands back. `shipments` publishes the event and has
  /// never heard of incidents.
  @lazySingleton
  ShipmentFailureWatcher incidentWatcher(
    DomainEventBus events,
    ReportIncident report,
    ReasonClassifier classify,
    Logger logger,
  ) => ShipmentFailureWatcher(
    events: events,
    report: report,
    classify: classify,
    logger: logger,
  );

  /// The one implementation of `IncidentsFacade`.
  @lazySingleton
  IncidentsFacade incidents(
    ReportIncident report,
    ListOpenIncidents list,
    EscalateOverdue escalate,
    ResolveIncident resolve,
  ) => IncidentsCoordinator(
    report: report,
    list: list,
    escalate: escalate,
    resolve: resolve,
  );

  // -- vehicle_inventory ---------------------------------------------------

  /// The depot's manifest, over HTTP.
  @lazySingleton
  HttpManifestSource httpManifests(HttpTransport transport) =>
      HttpManifestSource(transport: transport);

  /// The same manifest, cached.
  ///
  /// Scenario 4 in miniature, and the half people miss: two adapters for one
  /// port, *composed* rather than swapped. The cache is not an alternative to
  /// the HTTP source — it wraps it, and the use cases see one `ManifestSource`.
  @lazySingleton
  ManifestSource manifests(
    HttpManifestSource upstream,
    KeyValueStore store,
  ) => CachedManifestSource(upstream: upstream, store: store);

  /// The counts.
  @lazySingleton
  LoadCountStore counts(KeyValueStore store) =>
      KeyValueLoadCountStore(store: store);

  /// Opening one.
  @lazySingleton
  StartCount startCount(
    ManifestSource manifests,
    LoadCountStore store,
    Clock clock,
    IdGenerator ids,
  ) => StartCount(
    manifests: manifests,
    store: store,
    clock: clock,
    ids: ids,
  );

  /// Scanning a parcel into one.
  @lazySingleton
  RecordScan recordScan(LoadCountStore store) => RecordScan(store: store);

  /// Closing one.
  @lazySingleton
  CloseCount closeCount(LoadCountStore store, Clock clock, Logger logger) =>
      CloseCount(store: store, clock: clock, logger: logger);

  /// Picking up one that was already open.
  @lazySingleton
  FindOpenCount findCount(LoadCountStore store) => FindOpenCount(store: store);

  /// The one implementation of `VehicleInventoryFacade`.
  @lazySingleton
  VehicleInventoryFacade vehicleInventory(
    StartCount start,
    RecordScan record,
    CloseCount close,
    FindOpenCount find,
  ) => VehicleInventoryCoordinator(
    start: start,
    record: record,
    close: close,
    find: find,
  );

  // -- messaging -----------------------------------------------------------

  /// The threads, on the device.
  ///
  /// A courier reads a thread in a lift, so the store is the real one over
  /// SQLite. This is where messaging keeping its own queue rather than using
  /// sync's outbox becomes visible: the queued messages are in this store,
  /// beside the ones already sent, because a person can see them.
  @lazySingleton
  MessageStore messages(KeyValueStore store) =>
      KeyValueMessageStore(store: store);

  /// Sending one, over HTTP.
  @lazySingleton
  MessageTransport messageTransport(HttpTransport transport) =>
      HttpMessageTransport(transport: transport);

  /// Sending one message off the queue.
  @lazySingleton
  DeliverMessage deliver(
    MessageStore store,
    MessageTransport transport,
    Logger logger,
  ) => DeliverMessage(store: store, transport: transport, logger: logger);

  /// Reading a thread.
  @lazySingleton
  ReadThread readThread(MessageStore store) => ReadThread(store: store);

  /// Writing to one.
  @lazySingleton
  SendMessage sendMessage(
    MessageStore store,
    DeliverMessage deliver,
    Clock clock,
    IdGenerator ids,
  ) => SendMessage(store: store, deliver: deliver, clock: clock, ids: ids);

  /// Marking a thread read.
  @lazySingleton
  MarkThreadRead markThread(
    MessageStore store,
    MessageTransport transport,
    Clock clock,
  ) => MarkThreadRead(store: store, transport: transport, clock: clock);

  /// Emptying the queue.
  ///
  /// messaging's own queue, and not sync's outbox. The test phase 6 wrote
  /// down: if a person can see the queued thing, it belongs beside the thing
  /// they can see.
  @lazySingleton
  DrainQueue drainMessages(MessageStore store, DeliverMessage deliver) =>
      DrainQueue(store: store, deliver: deliver);

  /// The one implementation of `MessagingFacade`.
  @lazySingleton
  MessagingFacade messaging(
    ReadThread read,
    SendMessage send,
    MarkThreadRead mark,
    DrainQueue drain,
  ) => MessagingCoordinator(
    read: read,
    send: send,
    mark: mark,
    drain: drain,
  );

  // -- documents -----------------------------------------------------------

  /// The archive, capped.
  @lazySingleton
  DocumentArchive archive(KeyValueStore store) =>
      CappedDocumentArchive(store: store);

  /// The renderer, over HTTP.
  @lazySingleton
  DocumentRenderer renderer(HttpTransport transport, Clock clock) =>
      HttpDocumentRenderer(transport: transport, clock: clock);

  /// Getting a waybill.
  @lazySingleton
  ObtainDocument obtain(
    DocumentArchive archive,
    DocumentRenderer renderer,
    Logger logger,
  ) => ObtainDocument(archive: archive, renderer: renderer, logger: logger);

  /// The one implementation of `DocumentsFacade`.
  @lazySingleton
  DocumentsFacade documents(ObtainDocument obtain) =>
      DocumentsCoordinator(obtain: obtain);
}
