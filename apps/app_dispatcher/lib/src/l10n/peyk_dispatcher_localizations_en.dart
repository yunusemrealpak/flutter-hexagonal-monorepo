// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_dispatcher_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PeykDispatcherLocalizationsEn extends PeykDispatcherLocalizations {
  PeykDispatcherLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get identitySignInTitle => 'Sign in';

  @override
  String get identitySignInIdle => 'Sign in to open the board.';

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
      'This workstation has changed. Sign in again.';

  @override
  String get identityFailureSessionEnded =>
      'Your session ended. Sign in again.';

  @override
  String get identityFailureDisabled =>
      'This account is not active. Ask an administrator.';

  @override
  String get identityFailureUnavailable =>
      'The identity service did not answer. Try again.';

  @override
  String get identityFailureInternal =>
      'Something went wrong signing you in. Call the depot.';

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
  String get routingTitle => 'Courier route';

  @override
  String get routingUnplanned =>
      'No route has been planned for this courier yet.';

  @override
  String get routingNothingToDrive =>
      'This courier has nothing to drive today.';

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
  String get routingStopArrived => 'Mark arrived';

  @override
  String get routingStopMoveUp => 'Move up';

  @override
  String get routingFailureNoPlan =>
      'No route has been planned for this courier yet.';

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
      'No position reported. This is the route as planned.';

  @override
  String get routingFailurePlannerUnavailable =>
      'The solver did not answer. This route is the last one it returned.';

  @override
  String routingFailureMalformed(String field) {
    return 'Something is wrong with $field.';
  }

  @override
  String get paymentsTitle => 'Collection';

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
  String get paymentsCollect => 'Record payment';

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
      'The payments service did not answer.';

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
  String get syncReviewEmpty => 'Nothing needs a decision.';

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
    return '$count waiting for the service';
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
  String get syncFailureOffline =>
      'The service did not answer. This list may be stale.';

  @override
  String get syncFailureOutboxUnavailable => 'The queue could not be read.';

  @override
  String get syncFailureOther => 'Something went wrong. Try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsThemeSection => 'Appearance';

  @override
  String get settingsSyncSection => 'When couriers send';

  @override
  String get settingsAlertsSection => 'Alerts';

  @override
  String get settingsAlertsExplanation =>
      'Notifications about assignments and route changes on this device.';

  @override
  String get settingsAlertsToggle => 'Alerts on this device';

  @override
  String get settingsAlertsBlocked =>
      'Notifications are disabled for this application in the system settings.';

  @override
  String get settingsAlertsOpenSettings => 'Open system settings';

  @override
  String get settingsAlertsFailureRefused => 'Alerts were not enabled.';

  @override
  String get settingsAlertsFailureUnreachable =>
      'This device could not be registered for alerts.';

  @override
  String get settingsAlertsFailureUnavailable =>
      'The alert state could not be read.';

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
  String get notificationsInboxTitle => 'Operation notices';

  @override
  String get notificationsInboxEmpty => 'Nothing from the field.';

  @override
  String get notificationsFailureUnavailable =>
      'Your alerts could not be read.';

  @override
  String get notificationsFailureMissing => 'That alert is no longer here.';

  @override
  String get notificationsFailureRefused =>
      'Alerts are not available at a desk. Read them here instead.';

  @override
  String get notificationsFailureBlocked =>
      'Alerts are not available at a desk. Read them here instead.';

  @override
  String get notificationsFailureUnreachable =>
      'Alerts are not available at a desk.';

  @override
  String get notificationsFailureMalformed => 'An alert could not be read.';

  @override
  String get incidentsBoardTitle => 'Open problems';

  @override
  String get incidentsBoardClear => 'Nothing open across the operation.';

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
  String get messagingThreadTitle => 'Conversation';

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
      'The service would not take that message.';

  @override
  String get messagingFailureMissing => 'That message is no longer here.';

  @override
  String get messagingFailureMalformed => 'That message cannot be sent.';

  @override
  String get shipmentsDispatcherTitle => 'The board';

  @override
  String get shipmentsDispatcherEmpty => 'Nothing on the board.';

  @override
  String get shipmentsDispatcherLoadMore => 'Load more parcels';

  @override
  String get shipmentsDispatcherMoreFailed => 'The next parcels did not load.';

  @override
  String shipmentsDispatcherBulkAssign(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assign $count parcels',
      one: 'Assign 1 parcel',
      zero: 'Assign',
    );
    return '$_temp0';
  }

  @override
  String get shipmentsDispatcherFailureUnavailable =>
      'The board could not be loaded.';

  @override
  String get reportsTitle => 'The day';

  @override
  String get reportsForbidden => 'This report is not yours to read.';

  @override
  String get reportsTotalsSection => 'Totals';

  @override
  String reportsTotal(int count) {
    return '$count shipments';
  }

  @override
  String reportsDelivered(int count) {
    return '$count delivered';
  }

  @override
  String get reportsDaysSection => 'By day';

  @override
  String reportsDayRate(String day, int rate) {
    return '$rate%';
  }

  @override
  String get reportsFailureTally => 'The figures could not be read.';

  @override
  String get reportsFailureRange => 'That range starts after it ends.';

  @override
  String get reportsFailureMalformed =>
      'Some of the stored figures could not be read.';
}
