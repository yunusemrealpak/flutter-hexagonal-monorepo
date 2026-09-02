// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_courier_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PeykCourierLocalizationsEn extends PeykCourierLocalizations {
  PeykCourierLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get identitySignInTitle => 'Sign in';

  @override
  String get identitySignInIdle => 'Sign in to start your round.';

  @override
  String get identitySignInPending => 'Signing you in';

  @override
  String identitySignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get identityFailureRejected =>
      'Those details did not work. Check them and try again.';

  @override
  String get identityFailureDeviceChanged =>
      'This phone has changed. Sign in again to register it.';

  @override
  String get identityFailureSessionEnded =>
      'Your session ended. Sign in again.';

  @override
  String get identityFailureDisabled =>
      'This account is not active. Call the depot.';

  @override
  String get identityFailureUnavailable => 'No signal. Try again in a moment.';

  @override
  String get identityFailureInternal =>
      'Something went wrong signing you in. Call the depot.';

  @override
  String get shipmentsCourierTitle => 'Your stops';

  @override
  String get shipmentsCourierLoadMore => 'Load more stops';

  @override
  String get shipmentsCourierMoreFailed => 'The next stops did not load.';

  @override
  String get shipmentsCourierEmpty => 'Nothing assigned to you yet.';

  @override
  String get shipmentsCourierFailureUnavailable =>
      'No signal. Showing what is on this phone.';

  @override
  String get shipmentsCourierFailureNotFound =>
      'That parcel is no longer in the operation.';

  @override
  String get shipmentsCourierFailureOther => 'Something went wrong. Try again.';

  @override
  String get shipmentsStatusAwaitingAssignment => 'Unassigned';

  @override
  String get shipmentsStatusAssignedToCourier => 'Assigned';

  @override
  String get shipmentsStatusLoadedOnVehicle => 'On the van';

  @override
  String get shipmentsStatusOutForDelivery => 'Out for delivery';

  @override
  String get shipmentsStatusDelivered => 'Delivered';

  @override
  String get shipmentsStatusUndeliverable => 'Not delivered';

  @override
  String get shipmentsStatusReturned => 'Back at the depot';

  @override
  String get routingTitle => 'Your route';

  @override
  String get routingUnplanned => 'No route has been planned for you yet.';

  @override
  String get routingNothingToDrive => 'Nothing to drive today.';

  @override
  String routingSummary(int stops, DateTime finishesAt) {
    final intl.DateFormat finishesAtDateFormat = intl.DateFormat.Hm(localeName);
    final String finishesAtString = finishesAtDateFormat.format(finishesAt);

    return '$stops stops, back at $finishesAtString';
  }

  @override
  String routingStopArrivesAt(DateTime arrivesAt) {
    final intl.DateFormat arrivesAtDateFormat = intl.DateFormat.Hm(localeName);
    final String arrivesAtString = arrivesAtDateFormat.format(arrivesAt);

    return 'Arrives $arrivesAtString';
  }

  @override
  String get routingStopNext => 'Next';

  @override
  String get routingStopLate => 'Late';

  @override
  String get routingStopDone => 'Done';

  @override
  String get routingStopArrived => 'Arrived';

  @override
  String get routingStopMoveUp => 'Move up';

  @override
  String get routingFailureNoPlan => 'No route has been planned for you yet.';

  @override
  String get routingFailureSequenceMismatch =>
      'That order does not describe this route.';

  @override
  String get routingFailureUnsatisfiable =>
      'These stops cannot all be fitted in.';

  @override
  String routingFailureNotGeocoded(String address) {
    return 'One stop has no location: $address';
  }

  @override
  String get routingFailurePositionUnavailable =>
      'No position yet. This is the route as it was planned.';

  @override
  String get routingFailurePlannerUnavailable =>
      'The planner could not be reached. This route is from this phone.';

  @override
  String routingFailureMalformed(String field) {
    return 'Something is wrong with $field.';
  }

  @override
  String get deliveryTitle => 'At the door';

  @override
  String deliveryDelivering(String shipment) {
    return 'Delivering $shipment';
  }

  @override
  String get deliveryRecipientLabel => 'Who took it';

  @override
  String get deliveryRecipientHint => 'Name of the person at the door';

  @override
  String deliveryStillNeeded(String kinds) {
    return 'Still needed: $kinds';
  }

  @override
  String deliveryCaptured(String kind) {
    return 'Captured: $kind';
  }

  @override
  String get deliveryAddSignature => 'Add signature';

  @override
  String get deliverySignaturePrompt => 'Please sign here';

  @override
  String get deliveryAddPhoto => 'Add photo';

  @override
  String get deliveryDelivered => 'Delivered';

  @override
  String get deliveryCouldNotDeliver => 'Could not deliver';

  @override
  String get deliveryRecorded => 'Recorded.';

  @override
  String get deliveryEvidenceSignature => 'a signature';

  @override
  String get deliveryEvidencePhoto => 'a photo';

  @override
  String get deliveryEvidenceScan => 'a scan';

  @override
  String deliveryFailureOutsideArea(int metres) {
    return 'You are ${metres}m from the address.';
  }

  @override
  String get deliveryFailurePositionUnavailable =>
      'Your position could not be read. Step outside and try again.';

  @override
  String get deliveryFailurePositionBlocked =>
      'Location is switched off for this app. Turn it on in settings to record deliveries.';

  @override
  String get deliveryOpenSettings => 'Open settings';

  @override
  String get deliveryCaptureNotAllowed =>
      'That was refused. Tap again to be asked once more.';

  @override
  String get deliveryCaptureBlocked =>
      'Turn this on in settings to capture proof.';

  @override
  String deliveryFailureProofInsufficient(String kinds) {
    return 'This parcel needs $kinds.';
  }

  @override
  String get deliveryFailureAlreadySettled =>
      'This visit has already been recorded.';

  @override
  String get deliveryFailureProofStore => 'The evidence could not be saved.';

  @override
  String get deliveryFailureProofNotFound =>
      'That evidence is not on this phone.';

  @override
  String get deliveryFailureMediaTooLarge =>
      'That photograph is too big. Take another.';

  @override
  String get deliveryFailureUnavailable =>
      'This could not be queued. Try again.';

  @override
  String deliveryFailureMalformed(String field) {
    return 'Something is wrong with $field.';
  }

  @override
  String get paymentsTitle => 'Collect';

  @override
  String get paymentsNothingOwed => 'Nothing to collect on this parcel.';

  @override
  String paymentsOwed(int minorUnits, String currency, int scale) {
    return 'Owed $minorUnits $currency';
  }

  @override
  String paymentsTaken(int minorUnits, String currency, int scale) {
    return 'Taken $minorUnits $currency';
  }

  @override
  String paymentsTakingBy(String method) {
    return 'Taking by $method';
  }

  @override
  String get paymentsMethodCash => 'Cash';

  @override
  String get paymentsMethodCard => 'Card';

  @override
  String get paymentsCollect => 'Take payment';

  @override
  String get paymentsDone => 'Done';

  @override
  String paymentsFailureRefused(String reason) {
    return 'Refused: $reason';
  }

  @override
  String get paymentsFailureCashDrawer =>
      'The cash record could not be updated.';

  @override
  String get paymentsFailureUnavailable =>
      'This could not be recorded. Try again.';

  @override
  String get paymentsFailureAlreadySettled =>
      'This payment has already been taken.';

  @override
  String get paymentsFailureNothingToCollect =>
      'There is nothing to collect on this parcel.';

  @override
  String paymentsFailureRefundNotPossible(String reason) {
    return 'Cannot refund: $reason';
  }

  @override
  String get paymentsFailureSettlementUnavailable =>
      'Your day\'s total could not be read.';

  @override
  String get paymentsFailureSettlementClosed =>
      'Your day is already handed in.';

  @override
  String paymentsFailureCurrencyMismatch(int expected, String actual) {
    return 'This is in $actual and the collection is in $expected.';
  }

  @override
  String paymentsFailureMalformed(String field) {
    return 'Something is wrong with $field.';
  }

  @override
  String get syncReviewTitle => 'Stuck work';

  @override
  String get syncReviewEmpty => 'Nothing needs you.';

  @override
  String get syncReviewRetry => 'Try again';

  @override
  String syncReviewAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusIdle => 'Everything is sent';

  @override
  String syncStatusDraining(int count) {
    return 'Sending $count';
  }

  @override
  String syncStatusWaitingForNetwork(int count) {
    return '$count waiting for signal';
  }

  @override
  String syncStatusWaitingToRetry(int count) {
    return '$count will be retried';
  }

  @override
  String syncStatusBlocked(int count) {
    return '$count need you';
  }

  @override
  String get syncFailureOffline => 'No signal. This list is from this phone.';

  @override
  String get syncFailureOutboxUnavailable =>
      'The queue on this phone could not be read.';

  @override
  String get syncFailureOther => 'Something went wrong. Try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsThemeSection => 'Appearance';

  @override
  String get settingsSyncSection => 'When to send';

  @override
  String get settingsAlertsSection => 'Alerts';

  @override
  String get settingsAlertsExplanation =>
      'New jobs, route changes and messages from the office reach your phone as soon as they happen.';

  @override
  String get settingsAlertsToggle => 'Alerts on this phone';

  @override
  String get settingsAlertsBlocked =>
      'Alerts are switched off in the phone\'s own settings, so the app cannot ask for them.';

  @override
  String get settingsAlertsOpenSettings => 'Open phone settings';

  @override
  String get settingsAlertsFailureRefused =>
      'Alerts stayed off. You can turn them on whenever you like.';

  @override
  String get settingsAlertsFailureUnreachable =>
      'This phone could not be registered for alerts. Try again in a moment.';

  @override
  String get settingsAlertsFailureUnavailable =>
      'Whether alerts are on could not be read.';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsThemeSystem => 'Follow the phone';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSyncAlways => 'Always';

  @override
  String get settingsSyncUnmeteredOnly => 'Only on Wi-Fi';

  @override
  String get settingsSyncManual => 'Only when I say';

  @override
  String get settingsFailureUnavailable =>
      'Your settings could not be reached.';

  @override
  String get settingsFailureCorrupted => 'Your settings could not be read.';

  @override
  String settingsFailureMalformed(String field) {
    return 'That $field cannot be used.';
  }

  @override
  String get notificationsInboxTitle => 'Alerts';

  @override
  String get notificationsInboxEmpty => 'Nothing from the operation.';

  @override
  String get notificationsFailureUnavailable =>
      'Your alerts could not be read.';

  @override
  String get notificationsFailureMissing => 'That alert is no longer here.';

  @override
  String get notificationsFailureRefused =>
      'Alerts are off. Turn them on to be told about work.';

  @override
  String get notificationsFailureBlocked =>
      'Alerts are blocked in the phone\'s settings.';

  @override
  String get notificationsFailureUnreachable =>
      'This phone could not be registered for alerts.';

  @override
  String get notificationsFailureMalformed => 'An alert could not be read.';

  @override
  String get incidentsBoardTitle => 'Problems';

  @override
  String get incidentsBoardClear => 'Nothing open.';

  @override
  String get incidentsCategoryDamage => 'Damaged';

  @override
  String get incidentsCategoryAddressNotFound => 'Address not found';

  @override
  String get incidentsCategoryRecipientUnavailable => 'Nobody there';

  @override
  String get incidentsCategoryAccessDenied => 'Could not get in';

  @override
  String get incidentsCategoryFieldEmergency => 'Emergency';

  @override
  String get incidentsCategoryUnclassified => 'Something else';

  @override
  String get incidentsSeverityRoutine => 'Routine';

  @override
  String get incidentsSeverityUrgent => 'Urgent';

  @override
  String get incidentsSeverityCritical => 'Critical';

  @override
  String get incidentsFailureLogUnavailable =>
      'The problem list could not be read.';

  @override
  String get incidentsFailureMissing => 'That problem is no longer open.';

  @override
  String incidentsFailureNotInState(String attempted) {
    return 'This cannot be $attempted now.';
  }

  @override
  String incidentsFailureMalformed(String field) {
    return 'Something is wrong with the $field.';
  }

  @override
  String get inventoryTitle => 'Count the van';

  @override
  String get inventoryIdle => 'No count open. Start one to load or unload.';

  @override
  String get inventoryPreparing => 'Getting the load list';

  @override
  String inventoryProgress(int scanned, int expected) {
    return '$scanned of $expected';
  }

  @override
  String inventoryMissing(int count) {
    return '$count missing';
  }

  @override
  String inventoryUnexpected(int count) {
    return '$count not on the list';
  }

  @override
  String get inventoryReconciled => 'All accounted for';

  @override
  String get inventoryFailureManifest => 'The load list could not be reached.';

  @override
  String get inventoryFailureCount => 'This count could not be saved.';

  @override
  String get inventoryFailureCountMissing => 'That count is no longer open.';

  @override
  String get inventoryFailureCountClosed => 'This count is already finished.';

  @override
  String get inventoryFailureMalformed => 'The load list could not be read.';

  @override
  String get messagingThreadTitle => 'Messages';

  @override
  String get messagingThreadEmpty => 'Nothing said yet.';

  @override
  String messagingThreadQueued(int count) {
    return '$count waiting to send';
  }

  @override
  String get messagingStatusQueued => 'Waiting';

  @override
  String get messagingStatusSent => 'Sent';

  @override
  String get messagingStatusRead => 'Read';

  @override
  String get messagingFailureThread => 'This conversation could not be opened.';

  @override
  String get messagingFailureDeferred => 'Waiting for a connection.';

  @override
  String get messagingFailureRefused =>
      'The operation would not take that message.';

  @override
  String get messagingFailureMissing => 'That message is no longer here.';

  @override
  String get messagingFailureMalformed => 'That message cannot be sent.';

  @override
  String get documentsTitle => 'Paperwork';

  @override
  String get documentsShare => 'Share';

  @override
  String documentsSize(int bytes) {
    return '$bytes bytes';
  }

  @override
  String get documentsKindWaybill => 'Waybill';

  @override
  String get documentsKindReceipt => 'Delivery receipt';

  @override
  String get documentsKindDamageReport => 'Damage report';

  @override
  String get documentsFailureRender =>
      'This document could not be produced. Try again.';

  @override
  String documentsFailureRefused(String reason) {
    return 'The operation will not produce it: $reason';
  }

  @override
  String get documentsFailureArchive => 'The stored copy could not be read.';

  @override
  String get documentsFailureMissing => 'That document is no longer stored.';

  @override
  String get documentsFailureMalformed => 'That document could not be read.';

  @override
  String get courierTabStops => 'Stops';

  @override
  String get courierTabRoute => 'Route';

  @override
  String get courierTabInbox => 'Inbox';

  @override
  String get courierTabMore => 'More';
}
