import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../l10n/peyk_courier_localizations.dart';

/// This app's answer to every key its screens ask for.
///
/// **The `StringCatalogue` port, satisfied.** A presentation package writes
/// `settings.theme.dark` and cannot know what that says; the app knows,
/// because it is the only package that carries an `.arb` file and the only one
/// that knows which languages ship. That inversion is the reason the contract
/// is declared in `design_system` rather than here — section 2 gives a
/// presentation package that edge and gives it no app.
///
/// The words are a courier's. `app_dispatcher` answers the same keys with
/// different ones: "No signal, try again in a moment" to somebody in a van,
/// "The service did not answer" to somebody at a desk on ethernet. Neither is
/// a translation of the other, and neither presentation package changed.
///
/// **Every value is `gen-l10n`'s, and every argument is converted here.** The
/// generated getters are typed — an `int` count, a `DateTime` arrival — and a
/// key's arguments arrive as `Map<String, Object?>` because that is what a
/// screen can produce without knowing what the sentence needs. This class is
/// where the two meet, and the conversions below are deliberately total: a
/// screen that passed the wrong type gets a sensible value rather than a
/// crash in a van.
final class CourierCatalogue implements StringCatalogue {
  /// Creates the catalogue over [context]'s localisations.
  CourierCatalogue(BuildContext context)
    : _strings = PeykCourierLocalizations.of(context);

  final PeykCourierLocalizations _strings;

  @override
  String resolve(String key, {Map<String, Object?> arguments = const {}}) {
    final answer = _answers[key];
    // The fallback is the key itself, and the assertion is what stops that
    // being a silent gap. A key with no sentence is a mistake in the source,
    // and the catalogue coverage test walks every feature's manifest so that
    // it fails there rather than on a courier's screen — but a screen showing
    // `settings.theme.dark` is still a far better report of the bug than a
    // crash halfway through a delivery round.
    assert(answer != null, 'No sentence for "$key" in CourierCatalogue.');
    return answer?.call(_strings, arguments) ?? key;
  }

  /// Every key this app answers.
  ///
  /// Public so the coverage test can compare it against what the mounted
  /// features ask for, in both directions: a key nobody answers is a bug, and
  /// a sentence nobody asks for is a translation somebody is paying to
  /// maintain.
  static Set<String> get answered => _answers.keys.toSet();

  static int _int(Object? value) => switch (value) {
    final int it => it,
    final num it => it.round(),
    final String it => int.tryParse(it) ?? 0,
    _ => 0,
  };

  static String _text(Object? value) => value?.toString() ?? '';

  static String _list(Object? value) => switch (value) {
    final Iterable<Object?> it => it.map(_text).join(', '),
    _ => _text(value),
  };

  /// A local wall clock, which is the one place in the product that converts
  /// an instant into one.
  ///
  /// Every screen hands over UTC — `routing_presentation` says so where it
  /// builds the argument — because turning an instant into a time a courier
  /// reads needs a timezone, and the device is the only thing that has one.
  static DateTime _date(Object? value) => switch (value) {
    final DateTime it => it.toLocal(),
    final String it => DateTime.tryParse(it)?.toLocal() ?? DateTime.utc(0),
    _ => DateTime.utc(0),
  };

  /// `final` rather than `const`: a closure is not a constant expression, and
  /// every value here is one. The map is built once for the isolate.
  static final Map<
    String,
    String Function(PeykCourierLocalizations, Map<String, Object?>)
  >
  _answers = {
    'identity.signIn.title': (l, arguments) => l.identitySignInTitle,
    'identity.signIn.idle': (l, arguments) => l.identitySignInIdle,
    'identity.signIn.pending': (l, arguments) => l.identitySignInPending,
    'identity.signIn.signedInAs': (l, arguments) =>
        l.identitySignedInAs(_text(arguments['name'])),
    'identity.failure.rejected': (l, arguments) => l.identityFailureRejected,
    'identity.failure.deviceChanged': (l, arguments) =>
        l.identityFailureDeviceChanged,
    'identity.failure.sessionEnded': (l, arguments) =>
        l.identityFailureSessionEnded,
    'identity.failure.disabled': (l, arguments) => l.identityFailureDisabled,
    'identity.failure.unavailable': (l, arguments) =>
        l.identityFailureUnavailable,
    'identity.failure.internal': (l, arguments) => l.identityFailureInternal,
    'shipments.courier.title': (l, arguments) => l.shipmentsCourierTitle,
    'shipments.courier.empty': (l, arguments) => l.shipmentsCourierEmpty,
    'shipments.courier.failure.unavailable': (l, arguments) =>
        l.shipmentsCourierFailureUnavailable,
    'shipments.courier.failure.notFound': (l, arguments) =>
        l.shipmentsCourierFailureNotFound,
    'shipments.courier.failure.other': (l, arguments) =>
        l.shipmentsCourierFailureOther,
    'shipments.status.awaitingAssignment': (l, arguments) =>
        l.shipmentsStatusAwaitingAssignment,
    'shipments.status.assignedToCourier': (l, arguments) =>
        l.shipmentsStatusAssignedToCourier,
    'shipments.status.loadedOnVehicle': (l, arguments) =>
        l.shipmentsStatusLoadedOnVehicle,
    'shipments.status.outForDelivery': (l, arguments) =>
        l.shipmentsStatusOutForDelivery,
    'shipments.status.deliveredToConsignee': (l, arguments) =>
        l.shipmentsStatusDelivered,
    'shipments.status.undeliverable': (l, arguments) =>
        l.shipmentsStatusUndeliverable,
    'shipments.status.returnedToDepot': (l, arguments) =>
        l.shipmentsStatusReturned,
    'routing.title': (l, arguments) => l.routingTitle,
    'routing.unplanned': (l, arguments) => l.routingUnplanned,
    'routing.nothingToDrive': (l, arguments) => l.routingNothingToDrive,
    'routing.summary': (l, arguments) => l.routingSummary(
      _int(arguments['stops']),
      _date(arguments['finishesAt']),
    ),
    'routing.stop.arrivesAt': (l, arguments) =>
        l.routingStopArrivesAt(_date(arguments['arrivesAt'])),
    'routing.stop.next': (l, arguments) => l.routingStopNext,
    'routing.stop.late': (l, arguments) => l.routingStopLate,
    'routing.stop.done': (l, arguments) => l.routingStopDone,
    'routing.stop.arrived': (l, arguments) => l.routingStopArrived,
    'routing.stop.moveUp': (l, arguments) => l.routingStopMoveUp,
    'routing.failure.noPlan': (l, arguments) => l.routingFailureNoPlan,
    'routing.failure.sequenceMismatch': (l, arguments) =>
        l.routingFailureSequenceMismatch,
    'routing.failure.unsatisfiable': (l, arguments) =>
        l.routingFailureUnsatisfiable,
    'routing.failure.notGeocoded': (l, arguments) =>
        l.routingFailureNotGeocoded(_text(arguments['address'])),
    'routing.failure.positionUnavailable': (l, arguments) =>
        l.routingFailurePositionUnavailable,
    'routing.failure.plannerUnavailable': (l, arguments) =>
        l.routingFailurePlannerUnavailable,
    'routing.failure.malformed': (l, arguments) =>
        l.routingFailureMalformed(_text(arguments['field'])),
    'delivery.title': (l, arguments) => l.deliveryTitle,
    'delivery.delivering': (l, arguments) =>
        l.deliveryDelivering(_text(arguments['shipment'])),
    'delivery.recipient.label': (l, arguments) => l.deliveryRecipientLabel,
    'delivery.recipient.hint': (l, arguments) => l.deliveryRecipientHint,
    'delivery.stillNeeded': (l, arguments) =>
        l.deliveryStillNeeded(_list(arguments['kinds'])),
    'delivery.captured': (l, arguments) =>
        l.deliveryCaptured(_text(arguments['kind'])),
    'delivery.addSignature': (l, arguments) => l.deliveryAddSignature,
    'delivery.addPhoto': (l, arguments) => l.deliveryAddPhoto,
    'delivery.delivered': (l, arguments) => l.deliveryDelivered,
    'delivery.couldNotDeliver': (l, arguments) => l.deliveryCouldNotDeliver,
    'delivery.recorded': (l, arguments) => l.deliveryRecorded,
    'delivery.evidenceKind.signature': (l, arguments) =>
        l.deliveryEvidenceSignature,
    'delivery.evidenceKind.photo': (l, arguments) => l.deliveryEvidencePhoto,
    'delivery.evidenceKind.scan': (l, arguments) => l.deliveryEvidenceScan,
    'delivery.failure.outsideArea': (l, arguments) =>
        l.deliveryFailureOutsideArea(_int(arguments['metres'])),
    'delivery.failure.positionUnavailable': (l, arguments) =>
        l.deliveryFailurePositionUnavailable,
    'delivery.failure.positionBlocked': (l, arguments) =>
        l.deliveryFailurePositionBlocked,
    'delivery.openSettings': (l, arguments) => l.deliveryOpenSettings,
    'delivery.failure.proofInsufficient': (l, arguments) =>
        l.deliveryFailureProofInsufficient(_list(arguments['kinds'])),
    'delivery.failure.alreadySettled': (l, arguments) =>
        l.deliveryFailureAlreadySettled,
    'delivery.failure.proofStoreUnavailable': (l, arguments) =>
        l.deliveryFailureProofStore,
    'delivery.failure.proofNotFound': (l, arguments) =>
        l.deliveryFailureProofNotFound,
    'delivery.failure.mediaTooLarge': (l, arguments) =>
        l.deliveryFailureMediaTooLarge,
    'delivery.failure.unavailable': (l, arguments) =>
        l.deliveryFailureUnavailable,
    'delivery.failure.malformed': (l, arguments) =>
        l.deliveryFailureMalformed(_text(arguments['field'])),
    'payments.title': (l, arguments) => l.paymentsTitle,
    'payments.nothingOwed': (l, arguments) => l.paymentsNothingOwed,
    'payments.owed': (l, arguments) => l.paymentsOwed(
      _int(arguments['minorUnits']),
      _text(arguments['currency']),
      _int(arguments['scale']),
    ),
    'payments.taken': (l, arguments) => l.paymentsTaken(
      _int(arguments['minorUnits']),
      _text(arguments['currency']),
      _int(arguments['scale']),
    ),
    'payments.takingBy': (l, arguments) =>
        l.paymentsTakingBy(_text(arguments['method'])),
    'payments.method.cash': (l, arguments) => l.paymentsMethodCash,
    'payments.method.card': (l, arguments) => l.paymentsMethodCard,
    'payments.collect': (l, arguments) => l.paymentsCollect,
    'payments.done': (l, arguments) => l.paymentsDone,
    'payments.failure.refused': (l, arguments) =>
        l.paymentsFailureRefused(_text(arguments['reason'])),
    'payments.failure.cashDrawerUnavailable': (l, arguments) =>
        l.paymentsFailureCashDrawer,
    'payments.failure.unavailable': (l, arguments) =>
        l.paymentsFailureUnavailable,
    'payments.failure.alreadySettled': (l, arguments) =>
        l.paymentsFailureAlreadySettled,
    'payments.failure.nothingToCollect': (l, arguments) =>
        l.paymentsFailureNothingToCollect,
    'payments.failure.refundNotPossible': (l, arguments) =>
        l.paymentsFailureRefundNotPossible(_text(arguments['reason'])),
    'payments.failure.settlementUnavailable': (l, arguments) =>
        l.paymentsFailureSettlementUnavailable,
    'payments.failure.settlementClosed': (l, arguments) =>
        l.paymentsFailureSettlementClosed,
    'payments.failure.currencyMismatch': (l, arguments) =>
        l.paymentsFailureCurrencyMismatch(
          _int(arguments['expected']),
          _text(arguments['actual']),
        ),
    'payments.failure.malformed': (l, arguments) =>
        l.paymentsFailureMalformed(_text(arguments['field'])),
    'sync.review.title': (l, arguments) => l.syncReviewTitle,
    'sync.review.empty': (l, arguments) => l.syncReviewEmpty,
    'sync.review.retry': (l, arguments) => l.syncReviewRetry,
    'sync.review.attempts': (l, arguments) =>
        l.syncReviewAttempts(_int(arguments['count'])),
    'sync.status.idle': (l, arguments) => l.syncStatusIdle,
    'sync.status.draining': (l, arguments) =>
        l.syncStatusDraining(_int(arguments['count'])),
    'sync.status.waitingForNetwork': (l, arguments) =>
        l.syncStatusWaitingForNetwork(_int(arguments['count'])),
    'sync.status.waitingToRetry': (l, arguments) =>
        l.syncStatusWaitingToRetry(_int(arguments['count'])),
    'sync.status.blocked': (l, arguments) =>
        l.syncStatusBlocked(_int(arguments['count'])),
    'sync.failure.offline': (l, arguments) => l.syncFailureOffline,
    'sync.failure.outboxUnavailable': (l, arguments) =>
        l.syncFailureOutboxUnavailable,
    'sync.failure.other': (l, arguments) => l.syncFailureOther,
    'settings.title': (l, arguments) => l.settingsTitle,
    'settings.language.section': (l, arguments) => l.settingsLanguageSection,
    'settings.theme.section': (l, arguments) => l.settingsThemeSection,
    'settings.sync.section': (l, arguments) => l.settingsSyncSection,
    'settings.alerts.section': (l, arguments) => l.settingsAlertsSection,
    'settings.alerts.explanation': (l, arguments) =>
        l.settingsAlertsExplanation,
    'settings.alerts.toggle': (l, arguments) => l.settingsAlertsToggle,
    'settings.alerts.blocked': (l, arguments) => l.settingsAlertsBlocked,
    'settings.alerts.openSettings': (l, arguments) =>
        l.settingsAlertsOpenSettings,
    'settings.alerts.failure.refused': (l, arguments) =>
        l.settingsAlertsFailureRefused,
    'settings.alerts.failure.unreachable': (l, arguments) =>
        l.settingsAlertsFailureUnreachable,
    'settings.alerts.failure.unavailable': (l, arguments) =>
        l.settingsAlertsFailureUnavailable,
    'settings.signOut': (l, arguments) => l.settingsSignOut,
    'settings.language.tr': (l, arguments) => l.settingsLanguageTr,
    'settings.theme.system': (l, arguments) => l.settingsThemeSystem,
    'settings.theme.light': (l, arguments) => l.settingsThemeLight,
    'settings.theme.dark': (l, arguments) => l.settingsThemeDark,
    'settings.sync.always': (l, arguments) => l.settingsSyncAlways,
    'settings.sync.unmeteredOnly': (l, arguments) =>
        l.settingsSyncUnmeteredOnly,
    'settings.sync.manual': (l, arguments) => l.settingsSyncManual,
    'settings.failure.unavailable': (l, arguments) =>
        l.settingsFailureUnavailable,
    'settings.failure.corrupted': (l, arguments) => l.settingsFailureCorrupted,
    'settings.failure.malformed': (l, arguments) =>
        l.settingsFailureMalformed(_text(arguments['field'])),
    'notifications.inbox.title': (l, arguments) => l.notificationsInboxTitle,
    'notifications.inbox.empty': (l, arguments) => l.notificationsInboxEmpty,
    'notifications.failure.unavailable': (l, arguments) =>
        l.notificationsFailureUnavailable,
    'notifications.failure.missing': (l, arguments) =>
        l.notificationsFailureMissing,
    'notifications.failure.refused': (l, arguments) =>
        l.notificationsFailureRefused,
    'notifications.failure.blocked': (l, arguments) =>
        l.notificationsFailureBlocked,
    'notifications.failure.unreachable': (l, arguments) =>
        l.notificationsFailureUnreachable,
    'notifications.failure.malformed': (l, arguments) =>
        l.notificationsFailureMalformed,
    'incidents.board.title': (l, arguments) => l.incidentsBoardTitle,
    'incidents.board.clear': (l, arguments) => l.incidentsBoardClear,
    'incidents.category.damage': (l, arguments) => l.incidentsCategoryDamage,
    'incidents.category.addressNotFound': (l, arguments) =>
        l.incidentsCategoryAddressNotFound,
    'incidents.category.recipientUnavailable': (l, arguments) =>
        l.incidentsCategoryRecipientUnavailable,
    'incidents.category.accessDenied': (l, arguments) =>
        l.incidentsCategoryAccessDenied,
    'incidents.category.fieldEmergency': (l, arguments) =>
        l.incidentsCategoryFieldEmergency,
    'incidents.category.unclassified': (l, arguments) =>
        l.incidentsCategoryUnclassified,
    'incidents.severity.routine': (l, arguments) => l.incidentsSeverityRoutine,
    'incidents.severity.urgent': (l, arguments) => l.incidentsSeverityUrgent,
    'incidents.severity.critical': (l, arguments) =>
        l.incidentsSeverityCritical,
    'incidents.failure.logUnavailable': (l, arguments) =>
        l.incidentsFailureLogUnavailable,
    'incidents.failure.missing': (l, arguments) => l.incidentsFailureMissing,
    'incidents.failure.notInState': (l, arguments) =>
        l.incidentsFailureNotInState(_text(arguments['attempted'])),
    'incidents.failure.malformed': (l, arguments) =>
        l.incidentsFailureMalformed(_text(arguments['field'])),
    'inventory.title': (l, arguments) => l.inventoryTitle,
    'inventory.idle': (l, arguments) => l.inventoryIdle,
    'inventory.preparing': (l, arguments) => l.inventoryPreparing,
    'inventory.progress': (l, arguments) => l.inventoryProgress(
      _int(arguments['scanned']),
      _int(arguments['expected']),
    ),
    'inventory.missing': (l, arguments) =>
        l.inventoryMissing(_int(arguments['count'])),
    'inventory.unexpected': (l, arguments) =>
        l.inventoryUnexpected(_int(arguments['count'])),
    'inventory.reconciled': (l, arguments) => l.inventoryReconciled,
    'inventory.failure.manifestUnavailable': (l, arguments) =>
        l.inventoryFailureManifest,
    'inventory.failure.countUnavailable': (l, arguments) =>
        l.inventoryFailureCount,
    'inventory.failure.countMissing': (l, arguments) =>
        l.inventoryFailureCountMissing,
    'inventory.failure.countClosed': (l, arguments) =>
        l.inventoryFailureCountClosed,
    'inventory.failure.malformed': (l, arguments) =>
        l.inventoryFailureMalformed,
    'messaging.thread.title': (l, arguments) => l.messagingThreadTitle,
    'messaging.thread.empty': (l, arguments) => l.messagingThreadEmpty,
    'messaging.thread.queued': (l, arguments) =>
        l.messagingThreadQueued(_int(arguments['count'])),
    'messaging.status.queued': (l, arguments) => l.messagingStatusQueued,
    'messaging.status.sent': (l, arguments) => l.messagingStatusSent,
    'messaging.status.read': (l, arguments) => l.messagingStatusRead,
    'messaging.failure.threadUnavailable': (l, arguments) =>
        l.messagingFailureThread,
    'messaging.failure.deferred': (l, arguments) => l.messagingFailureDeferred,
    'messaging.failure.refused': (l, arguments) => l.messagingFailureRefused,
    'messaging.failure.missing': (l, arguments) => l.messagingFailureMissing,
    'messaging.failure.malformed': (l, arguments) =>
        l.messagingFailureMalformed,
    'documents.title': (l, arguments) => l.documentsTitle,
    'documents.share': (l, arguments) => l.documentsShare,
    'documents.size': (l, arguments) =>
        l.documentsSize(_int(arguments['bytes'])),
    'documents.kind.waybill': (l, arguments) => l.documentsKindWaybill,
    'documents.kind.deliveryReceipt': (l, arguments) => l.documentsKindReceipt,
    'documents.kind.damageReport': (l, arguments) =>
        l.documentsKindDamageReport,
    'documents.failure.renderFailed': (l, arguments) =>
        l.documentsFailureRender,
    'documents.failure.refused': (l, arguments) =>
        l.documentsFailureRefused(_text(arguments['reason'])),
    'documents.failure.archiveUnavailable': (l, arguments) =>
        l.documentsFailureArchive,
    'documents.failure.missing': (l, arguments) => l.documentsFailureMissing,
    'documents.failure.malformed': (l, arguments) =>
        l.documentsFailureMalformed,
    // The shell's own four. Not a feature's words: which tabs exist is this
    // app's decision, so what they are called is too.
    'courier.tab.stops': (l, arguments) => l.courierTabStops,
    'courier.tab.route': (l, arguments) => l.courierTabRoute,
    'courier.tab.inbox': (l, arguments) => l.courierTabInbox,
    'courier.tab.more': (l, arguments) => l.courierTabMore,
  };
}
