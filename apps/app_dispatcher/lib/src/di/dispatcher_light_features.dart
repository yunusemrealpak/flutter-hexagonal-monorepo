import 'package:core_ports/core_ports.dart';
import 'package:http_dio/http_dio.dart';
import 'package:incidents_api/incidents_api.dart';
import 'package:incidents_core/incidents_core.dart';
import 'package:injectable/injectable.dart';
import 'package:messaging_api/messaging_api.dart';
import 'package:messaging_core/messaging_core.dart';
import 'package:notifications_api/notifications_api.dart';
import 'package:notifications_core/notifications_core.dart';
import 'package:reporting_api/reporting_api.dart';
import 'package:reporting_core/reporting_core.dart';
import 'package:settings_api/settings_api.dart';
import 'package:settings_core/settings_core.dart';

import 'desk_alert_channel.dart';

/// The reduced-split features this app mounts, on their real adapters.
///
/// **Five, and a different five.** `reporting` is here and is absent from
/// `app_courier`; `vehicle_inventory` and `documents` are absent here and are
/// in that app. A van is counted by whoever is standing next to it, and a
/// waybill is the paperwork of whoever is carrying the parcel.
///
/// Set beside `CourierLightFeatures`, the overlap is settings, notifications,
/// incidents and messaging — the four every audience has. That is what an app
/// being a *set of features* looks like when it is written down rather than
/// asserted.
@module
abstract class DispatcherLightFeatures {
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

  /// The alert channel this app has, which is none.
  ///
  /// A dispatcher's alerts are rows on a board they are already looking at,
  /// so there is no push client here and `push_messaging` is not a dependency
  /// of this app. `NotificationsCoordinator` still takes an `AlertChannel` —
  /// use cases are the same package everywhere — so this app answers the port
  /// with an adapter that declines, which is a truthful answer rather than a
  /// stub: alerts genuinely cannot be turned on at a desk.
  @lazySingleton
  AlertChannel get alerts => const DeskAlertChannel();

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

  // -- messaging -----------------------------------------------------------

  /// The threads, on the device.
  ///
  /// A dispatcher reads a thread in a lift, so the store is the real one over
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
  /// `DispatcherWatchers` rather than here, so that a day's figures begin when
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
