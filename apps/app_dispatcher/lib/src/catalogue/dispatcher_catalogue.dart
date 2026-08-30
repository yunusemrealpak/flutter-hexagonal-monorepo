import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

import '../l10n/peyk_dispatcher_localizations.dart';

/// This app's answer to every key its screens ask for.
///
/// **The `StringCatalogue` port, satisfied.** A presentation package writes
/// `settings.theme.dark` and cannot know what that says; the app knows,
/// because it is the only package that carries an `.arb` file and the only one
/// that knows which languages ship. That inversion is the reason the contract
/// is declared in `design_system` rather than here — section 2 gives a
/// presentation package that edge and gives it no app.
///
/// **It carries no delivery sentences, and that is the finding this app's
/// coverage test produced.** `delivery` is *composed* here — the two driving
/// ports a desk can answer resolve, and `RemoteProofStore` is row 4 of the
/// adapter table — and none of its destinations is mounted. Composing a
/// feature is not the same as carrying its language: a sentence for a screen
/// this app never draws is a translation somebody maintains in every language
/// forever.
///
/// The words are a dispatcher's, and they are the same keys `app_courier`
/// answers differently. `identity.failure.unavailable` is "No signal, try
/// again in a moment" to somebody in a van and "The identity service did not
/// answer" to somebody at a desk on ethernet; `routing.title` is "Your route"
/// there and "Courier route" here, because a dispatcher is never looking at
/// their own. Neither is a translation of the other, and
/// `identity_presentation` changed for neither.
///
/// **Every value is `gen-l10n`'s, and every argument is converted here.** The
/// generated getters are typed — an `int` count, a `DateTime` arrival — and a
/// key's arguments arrive as `Map<String, Object?>` because that is what a
/// screen can produce without knowing what the sentence needs. This class is
/// where the two meet, and the conversions below are deliberately total: a
/// screen that passed the wrong type gets a sensible value rather than a
/// crash in a van.
final class DispatcherCatalogue implements StringCatalogue {
  /// Creates the catalogue over [context]'s localisations.
  DispatcherCatalogue(BuildContext context)
    : _strings = PeykDispatcherLocalizations.of(context);

  final PeykDispatcherLocalizations _strings;

  @override
  String resolve(String key, {Map<String, Object?> arguments = const {}}) {
    final answer = _answers[key];
    // The fallback is the key itself, and the assertion is what stops that
    // being a silent gap. A key with no sentence is a mistake in the source,
    // and the catalogue coverage test walks every feature's manifest so that
    // it fails there rather than on a dispatcher's screen — but showing
    // `settings.theme.dark` is still a far better report of the bug than a
    // crash in the middle of a shift.
    assert(answer != null, 'No sentence for "$key" in DispatcherCatalogue.');
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

  // `app_courier` has a `_list` beside these, for delivery's "still needed:
  // a signature and a photo". Nothing here takes a list, because the one key
  // that did belonged to a screen this app does not draw.

  /// A local wall clock, which is the one place in the product that converts
  /// an instant into one.
  ///
  /// Every screen hands over UTC — `routing_presentation` says so where it
  /// builds the argument — because turning an instant into a time a dispatcher
  /// reads needs a timezone, and the device is the only thing that has one.
  static DateTime _date(Object? value) => switch (value) {
    final DateTime it => it.toLocal(),
    final String it => DateTime.tryParse(it)?.toLocal() ?? DateTime.utc(0),
    _ => DateTime.utc(0),
  };

  /// `final` rather than `const`: a closure is not a constant expression, and
  /// every value here is one. The map is built once for the isolate.
  /// `final` rather than `const`: a closure is not a constant expression, and
  /// every value here is one. The map is built once for the isolate.
  static final Map<
    String,
    String Function(PeykDispatcherLocalizations, Map<String, Object?>)
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
    'shipments.dispatcher.title': (l, arguments) => l.shipmentsDispatcherTitle,
    'shipments.dispatcher.empty': (l, arguments) => l.shipmentsDispatcherEmpty,
    'shipments.dispatcher.bulkAssign': (l, arguments) =>
        l.shipmentsDispatcherBulkAssign(_int(arguments['count'])),
    'shipments.dispatcher.failure.unavailable': (l, arguments) =>
        l.shipmentsDispatcherFailureUnavailable,
    'reports.title': (l, arguments) => l.reportsTitle,
    'reports.forbidden': (l, arguments) => l.reportsForbidden,
    'reports.totals.section': (l, arguments) => l.reportsTotalsSection,
    'reports.total': (l, arguments) => l.reportsTotal(_int(arguments['count'])),
    'reports.delivered': (l, arguments) =>
        l.reportsDelivered(_int(arguments['count'])),
    'reports.days.section': (l, arguments) => l.reportsDaysSection,
    'reports.day.rate': (l, arguments) =>
        l.reportsDayRate(_text(arguments['day']), _int(arguments['rate'])),
    'reports.failure.tallyUnavailable': (l, arguments) => l.reportsFailureTally,
    'reports.failure.rangeInverted': (l, arguments) => l.reportsFailureRange,
    'reports.failure.malformed': (l, arguments) => l.reportsFailureMalformed,
  };
}
