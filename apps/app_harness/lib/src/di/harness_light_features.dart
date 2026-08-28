import 'package:core_ports/core_ports.dart';
import 'package:documents_api/documents_api.dart';
import 'package:documents_core/documents_core.dart';
import 'package:http_dio/http_dio.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_core/incidents_core.dart';
import 'package:injectable/injectable.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_core/messaging_core.dart';
import 'package:messaging_testing/messaging_testing.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_core/notifications_core.dart';
import 'package:push_messaging/push_messaging.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_core/reporting_core.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';
import 'package:vehicle_inventory_core/vehicle_inventory_core.dart';

/// The seven reduced-split features, on fakes.
///
/// **These bind the real adapters, not fakes of them**, and that is the point
/// rather than a shortcut. `KeyValuePreferencesStore` over an
/// `InMemoryKeyValueStore` exercises the mapping, the namespacing and the
/// failure translation that a `FakePreferencesStore` would have replaced with
/// a map. Six of these features ship no `_testing` package precisely because
/// nothing needed one — the fake belongs one layer further out, at the driven
/// port the adapter is written against.
///
/// `messaging` is the exception, and it is the exception for the reason phase
/// 6 gave: its fakes are consumed by two other packages, so it has a
/// `_testing` package and this module uses it.
///
/// One module for seven features rather than seven modules. Each is three or
/// four registrations, and a file per feature here would be a file per feature
/// to open before finding out that nothing interesting happens in it.
@module
abstract class HarnessLightFeatures {
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

  /// A push client that delivers nowhere.
  ///
  /// It comes from `platform/push_messaging` rather than from a `_testing`
  /// package, because `PushMessagingClient` is a *technology* contract and
  /// §2.2 puts a fake beside the contract it imitates.
  @lazySingleton
  FakePushMessagingClient get fakePush => FakePushMessagingClient();

  /// The same instance, as the technology contract.
  @lazySingleton
  PushMessagingClient push(FakePushMessagingClient fake) => fake;

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

  /// Turning alerts on.
  @lazySingleton
  OpenAlerts openAlerts(AlertChannel channel) => OpenAlerts(channel: channel);

  /// Turning them off.
  @lazySingleton
  CloseAlerts closeAlerts(AlertChannel channel) =>
      CloseAlerts(channel: channel);

  /// The one implementation of `NotificationsFacade`.
  @lazySingleton
  NotificationsFacade notifications(
    ReadInbox read,
    MarkAlertRead mark,
    RecordArrivingAlert record,
    OpenAlerts open,
    CloseAlerts close,
    AlertChannel channel,
    Logger logger,
  ) => NotificationsCoordinator(
    read: read,
    mark: mark,
    record: record,
    open: open,
    close: close,
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

  /// The threads.
  ///
  /// The one light feature whose fakes another package consumes, so the fake
  /// comes from `messaging_testing` rather than being the real adapter over a
  /// fake store.
  @lazySingleton
  InMemoryMessageStore get fakeMessages => InMemoryMessageStore();

  /// The same instance, as the port.
  @lazySingleton
  MessageStore messages(InMemoryMessageStore fake) => fake;

  /// A transport that takes everything.
  @lazySingleton
  FakeMessageTransport get fakeMessageTransport => FakeMessageTransport();

  /// The same instance, as the port.
  @lazySingleton
  MessageTransport messageTransport(FakeMessageTransport fake) => fake;

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

  // -- reporting -----------------------------------------------------------

  /// The tallies.
  @lazySingleton
  TallyStore tallies(KeyValueStore store) => KeyValueTallyStore(store: store);

  /// Adding one outcome to a day.
  @lazySingleton
  RecordOutcome recordOutcome(TallyStore store) => RecordOutcome(store: store);

  /// Reading a range of days.
  @lazySingleton
  ReadRange readRange(TallyStore store) => ReadRange(store: store);

  /// The read model's watcher.
  ///
  /// A read model rather than a reaction: it accumulates from events that
  /// other features publish, and `shipments` has never heard of it. Started by
  /// `HarnessWatchers` rather than here, so that a day's figures begin when
  /// the app comes up and not at whatever moment somebody first opens the
  /// report.
  @lazySingleton
  ShipmentOutcomeWatcher reportingWatcher(
    DomainEventBus events,
    RecordOutcome record,
    Logger logger,
  ) => ShipmentOutcomeWatcher(
    events: events,
    record: record,
    logger: logger,
  );

  /// The one implementation of `ReportingFacade`.
  @lazySingleton
  ReportingFacade reporting(TallyStore store, ReadRange range) =>
      ReportingCoordinator(store: store, range: range);
}
