import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'peyk_courier_localizations_en.dart';
import 'peyk_courier_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PeykCourierLocalizations
/// returned by `PeykCourierLocalizations.of(context)`.
///
/// Applications need to include `PeykCourierLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/peyk_courier_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PeykCourierLocalizations.localizationsDelegates,
///   supportedLocales: PeykCourierLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the PeykCourierLocalizations.supportedLocales
/// property.
abstract class PeykCourierLocalizations {
  PeykCourierLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PeykCourierLocalizations of(BuildContext context) {
    return Localizations.of<PeykCourierLocalizations>(
      context,
      PeykCourierLocalizations,
    )!;
  }

  static const LocalizationsDelegate<PeykCourierLocalizations> delegate =
      _PeykCourierLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The sentence behind "identity.signIn.title".
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get identitySignInTitle;

  /// The sentence behind "identity.signIn.idle".
  ///
  /// In en, this message translates to:
  /// **'Sign in to start your round.'**
  String get identitySignInIdle;

  /// The sentence behind "identity.signIn.pending".
  ///
  /// In en, this message translates to:
  /// **'Signing you in'**
  String get identitySignInPending;

  /// The sentence behind "identity.signIn.signedInAs".
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String identitySignedInAs(String name);

  /// The sentence behind "identity.failure.rejected".
  ///
  /// In en, this message translates to:
  /// **'Those details did not work. Check them and try again.'**
  String get identityFailureRejected;

  /// The sentence behind "identity.failure.deviceChanged".
  ///
  /// In en, this message translates to:
  /// **'This phone has changed. Sign in again to register it.'**
  String get identityFailureDeviceChanged;

  /// The sentence behind "identity.failure.sessionEnded".
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get identityFailureSessionEnded;

  /// The sentence behind "identity.failure.disabled".
  ///
  /// In en, this message translates to:
  /// **'This account is not active. Call the depot.'**
  String get identityFailureDisabled;

  /// The sentence behind "identity.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'No signal. Try again in a moment.'**
  String get identityFailureUnavailable;

  /// The sentence behind "identity.failure.internal".
  ///
  /// In en, this message translates to:
  /// **'Something went wrong signing you in. Call the depot.'**
  String get identityFailureInternal;

  /// The sentence behind "shipments.courier.title".
  ///
  /// In en, this message translates to:
  /// **'Your stops'**
  String get shipmentsCourierTitle;

  /// The sentence behind "shipments.courier.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing assigned to you yet.'**
  String get shipmentsCourierEmpty;

  /// The sentence behind "shipments.courier.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'No signal. Showing what is on this phone.'**
  String get shipmentsCourierFailureUnavailable;

  /// The sentence behind "shipments.courier.failure.notFound".
  ///
  /// In en, this message translates to:
  /// **'That parcel is no longer in the operation.'**
  String get shipmentsCourierFailureNotFound;

  /// The sentence behind "shipments.courier.failure.other".
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get shipmentsCourierFailureOther;

  /// The sentence behind "shipments.status.awaitingAssignment".
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get shipmentsStatusAwaitingAssignment;

  /// The sentence behind "shipments.status.assignedToCourier".
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get shipmentsStatusAssignedToCourier;

  /// The sentence behind "shipments.status.loadedOnVehicle".
  ///
  /// In en, this message translates to:
  /// **'On the van'**
  String get shipmentsStatusLoadedOnVehicle;

  /// The sentence behind "shipments.status.outForDelivery".
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get shipmentsStatusOutForDelivery;

  /// The sentence behind "shipments.status.deliveredToConsignee".
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get shipmentsStatusDelivered;

  /// The sentence behind "shipments.status.undeliverable".
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get shipmentsStatusUndeliverable;

  /// The sentence behind "shipments.status.returnedToDepot".
  ///
  /// In en, this message translates to:
  /// **'Back at the depot'**
  String get shipmentsStatusReturned;

  /// The sentence behind "routing.title".
  ///
  /// In en, this message translates to:
  /// **'Your route'**
  String get routingTitle;

  /// The sentence behind "routing.unplanned".
  ///
  /// In en, this message translates to:
  /// **'No route has been planned for you yet.'**
  String get routingUnplanned;

  /// The sentence behind "routing.nothingToDrive".
  ///
  /// In en, this message translates to:
  /// **'Nothing to drive today.'**
  String get routingNothingToDrive;

  /// The sentence behind "routing.summary".
  ///
  /// In en, this message translates to:
  /// **'{stops} stops, back at {finishesAt}'**
  String routingSummary(int stops, DateTime finishesAt);

  /// The sentence behind "routing.stop.arrivesAt".
  ///
  /// In en, this message translates to:
  /// **'Arrives {arrivesAt}'**
  String routingStopArrivesAt(DateTime arrivesAt);

  /// The sentence behind "routing.stop.next".
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get routingStopNext;

  /// The sentence behind "routing.stop.late".
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get routingStopLate;

  /// The sentence behind "routing.stop.done".
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get routingStopDone;

  /// The sentence behind "routing.stop.arrived".
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get routingStopArrived;

  /// The sentence behind "routing.stop.moveUp".
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get routingStopMoveUp;

  /// The sentence behind "routing.failure.noPlan".
  ///
  /// In en, this message translates to:
  /// **'No route has been planned for you yet.'**
  String get routingFailureNoPlan;

  /// The sentence behind "routing.failure.sequenceMismatch".
  ///
  /// In en, this message translates to:
  /// **'That order does not describe this route.'**
  String get routingFailureSequenceMismatch;

  /// The sentence behind "routing.failure.unsatisfiable".
  ///
  /// In en, this message translates to:
  /// **'These stops cannot all be fitted in.'**
  String get routingFailureUnsatisfiable;

  /// The sentence behind "routing.failure.notGeocoded".
  ///
  /// In en, this message translates to:
  /// **'One stop has no location: {address}'**
  String routingFailureNotGeocoded(String address);

  /// The sentence behind "routing.failure.positionUnavailable".
  ///
  /// In en, this message translates to:
  /// **'No position yet. This is the route as it was planned.'**
  String get routingFailurePositionUnavailable;

  /// The sentence behind "routing.failure.plannerUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The planner could not be reached. This route is from this phone.'**
  String get routingFailurePlannerUnavailable;

  /// The sentence behind "routing.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with {field}.'**
  String routingFailureMalformed(String field);

  /// The sentence behind "delivery.title".
  ///
  /// In en, this message translates to:
  /// **'At the door'**
  String get deliveryTitle;

  /// The sentence behind "delivery.delivering".
  ///
  /// In en, this message translates to:
  /// **'Delivering {shipment}'**
  String deliveryDelivering(String shipment);

  /// The sentence behind "delivery.recipient.label".
  ///
  /// In en, this message translates to:
  /// **'Who took it'**
  String get deliveryRecipientLabel;

  /// The sentence behind "delivery.recipient.hint".
  ///
  /// In en, this message translates to:
  /// **'Name of the person at the door'**
  String get deliveryRecipientHint;

  /// The sentence behind "delivery.stillNeeded".
  ///
  /// In en, this message translates to:
  /// **'Still needed: {kinds}'**
  String deliveryStillNeeded(String kinds);

  /// The sentence behind "delivery.captured".
  ///
  /// In en, this message translates to:
  /// **'Captured: {kind}'**
  String deliveryCaptured(String kind);

  /// The sentence behind "delivery.addSignature".
  ///
  /// In en, this message translates to:
  /// **'Add signature'**
  String get deliveryAddSignature;

  /// The sentence behind "delivery.addPhoto".
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get deliveryAddPhoto;

  /// The sentence behind "delivery.delivered".
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDelivered;

  /// The sentence behind "delivery.couldNotDeliver".
  ///
  /// In en, this message translates to:
  /// **'Could not deliver'**
  String get deliveryCouldNotDeliver;

  /// The sentence behind "delivery.recorded".
  ///
  /// In en, this message translates to:
  /// **'Recorded.'**
  String get deliveryRecorded;

  /// The sentence behind "delivery.evidenceKind.signature".
  ///
  /// In en, this message translates to:
  /// **'a signature'**
  String get deliveryEvidenceSignature;

  /// The sentence behind "delivery.evidenceKind.photo".
  ///
  /// In en, this message translates to:
  /// **'a photo'**
  String get deliveryEvidencePhoto;

  /// The sentence behind "delivery.evidenceKind.scan".
  ///
  /// In en, this message translates to:
  /// **'a scan'**
  String get deliveryEvidenceScan;

  /// The sentence behind "delivery.failure.outsideArea".
  ///
  /// In en, this message translates to:
  /// **'You are {metres}m from the address.'**
  String deliveryFailureOutsideArea(int metres);

  /// The sentence behind "delivery.failure.positionUnavailable".
  ///
  /// In en, this message translates to:
  /// **'Your position could not be read. Step outside and try again.'**
  String get deliveryFailurePositionUnavailable;

  /// The sentence behind "delivery.failure.proofInsufficient".
  ///
  /// In en, this message translates to:
  /// **'This parcel needs {kinds}.'**
  String deliveryFailureProofInsufficient(String kinds);

  /// The sentence behind "delivery.failure.alreadySettled".
  ///
  /// In en, this message translates to:
  /// **'This visit has already been recorded.'**
  String get deliveryFailureAlreadySettled;

  /// The sentence behind "delivery.failure.proofStoreUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The evidence could not be saved.'**
  String get deliveryFailureProofStore;

  /// The sentence behind "delivery.failure.proofNotFound".
  ///
  /// In en, this message translates to:
  /// **'That evidence is not on this phone.'**
  String get deliveryFailureProofNotFound;

  /// The sentence behind "delivery.failure.mediaTooLarge".
  ///
  /// In en, this message translates to:
  /// **'That photograph is too big. Take another.'**
  String get deliveryFailureMediaTooLarge;

  /// The sentence behind "delivery.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'This could not be queued. Try again.'**
  String get deliveryFailureUnavailable;

  /// The sentence behind "delivery.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with {field}.'**
  String deliveryFailureMalformed(String field);

  /// The sentence behind "payments.title".
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get paymentsTitle;

  /// The sentence behind "payments.nothingOwed".
  ///
  /// In en, this message translates to:
  /// **'Nothing to collect on this parcel.'**
  String get paymentsNothingOwed;

  /// The sentence behind "payments.owed".
  ///
  /// In en, this message translates to:
  /// **'Owed {minorUnits} {currency}'**
  String paymentsOwed(int minorUnits, String currency, int scale);

  /// The sentence behind "payments.taken".
  ///
  /// In en, this message translates to:
  /// **'Taken {minorUnits} {currency}'**
  String paymentsTaken(int minorUnits, String currency, int scale);

  /// The sentence behind "payments.takingBy".
  ///
  /// In en, this message translates to:
  /// **'Taking by {method}'**
  String paymentsTakingBy(String method);

  /// The sentence behind "payments.method.cash".
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentsMethodCash;

  /// The sentence behind "payments.method.card".
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentsMethodCard;

  /// The sentence behind "payments.collect".
  ///
  /// In en, this message translates to:
  /// **'Take payment'**
  String get paymentsCollect;

  /// The sentence behind "payments.failure.refused".
  ///
  /// In en, this message translates to:
  /// **'Refused: {reason}'**
  String paymentsFailureRefused(String reason);

  /// The sentence behind "payments.failure.cashDrawerUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The cash record could not be updated.'**
  String get paymentsFailureCashDrawer;

  /// The sentence behind "payments.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'This could not be recorded. Try again.'**
  String get paymentsFailureUnavailable;

  /// The sentence behind "payments.failure.alreadySettled".
  ///
  /// In en, this message translates to:
  /// **'This payment has already been taken.'**
  String get paymentsFailureAlreadySettled;

  /// The sentence behind "payments.failure.nothingToCollect".
  ///
  /// In en, this message translates to:
  /// **'There is nothing to collect on this parcel.'**
  String get paymentsFailureNothingToCollect;

  /// The sentence behind "payments.failure.refundNotPossible".
  ///
  /// In en, this message translates to:
  /// **'Cannot refund: {reason}'**
  String paymentsFailureRefundNotPossible(String reason);

  /// The sentence behind "payments.failure.settlementUnavailable".
  ///
  /// In en, this message translates to:
  /// **'Your day\'s total could not be read.'**
  String get paymentsFailureSettlementUnavailable;

  /// The sentence behind "payments.failure.settlementClosed".
  ///
  /// In en, this message translates to:
  /// **'Your day is already handed in.'**
  String get paymentsFailureSettlementClosed;

  /// The sentence behind "payments.failure.currencyMismatch".
  ///
  /// In en, this message translates to:
  /// **'This is in {actual} and the collection is in {expected}.'**
  String paymentsFailureCurrencyMismatch(int expected, String actual);

  /// The sentence behind "payments.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with {field}.'**
  String paymentsFailureMalformed(String field);

  /// The sentence behind "sync.review.title".
  ///
  /// In en, this message translates to:
  /// **'Stuck work'**
  String get syncReviewTitle;

  /// The sentence behind "sync.review.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing needs you.'**
  String get syncReviewEmpty;

  /// The sentence behind "sync.review.retry".
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get syncReviewRetry;

  /// The sentence behind "sync.review.attempts".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String syncReviewAttempts(int count);

  /// The sentence behind "sync.status.idle".
  ///
  /// In en, this message translates to:
  /// **'Everything is sent'**
  String get syncStatusIdle;

  /// The sentence behind "sync.status.draining".
  ///
  /// In en, this message translates to:
  /// **'Sending {count}'**
  String syncStatusDraining(int count);

  /// The sentence behind "sync.status.waitingForNetwork".
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for signal'**
  String syncStatusWaitingForNetwork(int count);

  /// The sentence behind "sync.status.waitingToRetry".
  ///
  /// In en, this message translates to:
  /// **'{count} will be retried'**
  String syncStatusWaitingToRetry(int count);

  /// The sentence behind "sync.status.blocked".
  ///
  /// In en, this message translates to:
  /// **'{count} need you'**
  String syncStatusBlocked(int count);

  /// The sentence behind "sync.failure.offline".
  ///
  /// In en, this message translates to:
  /// **'No signal. This list is from this phone.'**
  String get syncFailureOffline;

  /// The sentence behind "sync.failure.outboxUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The queue on this phone could not be read.'**
  String get syncFailureOutboxUnavailable;

  /// The sentence behind "sync.failure.other".
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get syncFailureOther;

  /// The sentence behind "settings.title".
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// The sentence behind "settings.language.section".
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// The sentence behind "settings.theme.section".
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsThemeSection;

  /// The sentence behind "settings.sync.section".
  ///
  /// In en, this message translates to:
  /// **'When to send'**
  String get settingsSyncSection;

  /// The sentence behind "settings.language.tr".
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTr;

  /// The sentence behind "settings.theme.system".
  ///
  /// In en, this message translates to:
  /// **'Follow the phone'**
  String get settingsThemeSystem;

  /// The sentence behind "settings.theme.light".
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// The sentence behind "settings.theme.dark".
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// The sentence behind "settings.sync.always".
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settingsSyncAlways;

  /// The sentence behind "settings.sync.unmeteredOnly".
  ///
  /// In en, this message translates to:
  /// **'Only on Wi-Fi'**
  String get settingsSyncUnmeteredOnly;

  /// The sentence behind "settings.sync.manual".
  ///
  /// In en, this message translates to:
  /// **'Only when I say'**
  String get settingsSyncManual;

  /// The sentence behind "settings.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'Your settings could not be reached.'**
  String get settingsFailureUnavailable;

  /// The sentence behind "settings.failure.corrupted".
  ///
  /// In en, this message translates to:
  /// **'Your settings could not be read.'**
  String get settingsFailureCorrupted;

  /// The sentence behind "settings.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'That {field} cannot be used.'**
  String settingsFailureMalformed(String field);

  /// The sentence behind "notifications.inbox.title".
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notificationsInboxTitle;

  /// The sentence behind "notifications.inbox.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing from the operation.'**
  String get notificationsInboxEmpty;

  /// The sentence behind "notifications.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'Your alerts could not be read.'**
  String get notificationsFailureUnavailable;

  /// The sentence behind "notifications.failure.missing".
  ///
  /// In en, this message translates to:
  /// **'That alert is no longer here.'**
  String get notificationsFailureMissing;

  /// The sentence behind "notifications.failure.refused".
  ///
  /// In en, this message translates to:
  /// **'Alerts are off. Turn them on to be told about work.'**
  String get notificationsFailureRefused;

  /// The sentence behind "notifications.failure.blocked".
  ///
  /// In en, this message translates to:
  /// **'Alerts are blocked in the phone\'s settings.'**
  String get notificationsFailureBlocked;

  /// The sentence behind "notifications.failure.unreachable".
  ///
  /// In en, this message translates to:
  /// **'This phone could not be registered for alerts.'**
  String get notificationsFailureUnreachable;

  /// The sentence behind "notifications.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'An alert could not be read.'**
  String get notificationsFailureMalformed;

  /// The sentence behind "incidents.board.title".
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get incidentsBoardTitle;

  /// The sentence behind "incidents.board.clear".
  ///
  /// In en, this message translates to:
  /// **'Nothing open.'**
  String get incidentsBoardClear;

  /// The sentence behind "incidents.category.damage".
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get incidentsCategoryDamage;

  /// The sentence behind "incidents.category.addressNotFound".
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get incidentsCategoryAddressNotFound;

  /// The sentence behind "incidents.category.recipientUnavailable".
  ///
  /// In en, this message translates to:
  /// **'Nobody there'**
  String get incidentsCategoryRecipientUnavailable;

  /// The sentence behind "incidents.category.accessDenied".
  ///
  /// In en, this message translates to:
  /// **'Could not get in'**
  String get incidentsCategoryAccessDenied;

  /// The sentence behind "incidents.category.fieldEmergency".
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get incidentsCategoryFieldEmergency;

  /// The sentence behind "incidents.category.unclassified".
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get incidentsCategoryUnclassified;

  /// The sentence behind "incidents.severity.routine".
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get incidentsSeverityRoutine;

  /// The sentence behind "incidents.severity.urgent".
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get incidentsSeverityUrgent;

  /// The sentence behind "incidents.severity.critical".
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get incidentsSeverityCritical;

  /// The sentence behind "incidents.failure.logUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The problem list could not be read.'**
  String get incidentsFailureLogUnavailable;

  /// The sentence behind "incidents.failure.missing".
  ///
  /// In en, this message translates to:
  /// **'That problem is no longer open.'**
  String get incidentsFailureMissing;

  /// The sentence behind "incidents.failure.notInState".
  ///
  /// In en, this message translates to:
  /// **'This cannot be {attempted} now.'**
  String incidentsFailureNotInState(String attempted);

  /// The sentence behind "incidents.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with the {field}.'**
  String incidentsFailureMalformed(String field);

  /// The sentence behind "inventory.title".
  ///
  /// In en, this message translates to:
  /// **'Count the van'**
  String get inventoryTitle;

  /// The sentence behind "inventory.idle".
  ///
  /// In en, this message translates to:
  /// **'No count open. Start one to load or unload.'**
  String get inventoryIdle;

  /// The sentence behind "inventory.preparing".
  ///
  /// In en, this message translates to:
  /// **'Getting the load list'**
  String get inventoryPreparing;

  /// The sentence behind "inventory.progress".
  ///
  /// In en, this message translates to:
  /// **'{scanned} of {expected}'**
  String inventoryProgress(int scanned, int expected);

  /// The sentence behind "inventory.missing".
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String inventoryMissing(int count);

  /// The sentence behind "inventory.unexpected".
  ///
  /// In en, this message translates to:
  /// **'{count} not on the list'**
  String inventoryUnexpected(int count);

  /// The sentence behind "inventory.reconciled".
  ///
  /// In en, this message translates to:
  /// **'All accounted for'**
  String get inventoryReconciled;

  /// The sentence behind "inventory.failure.manifestUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The load list could not be reached.'**
  String get inventoryFailureManifest;

  /// The sentence behind "inventory.failure.countUnavailable".
  ///
  /// In en, this message translates to:
  /// **'This count could not be saved.'**
  String get inventoryFailureCount;

  /// The sentence behind "inventory.failure.countMissing".
  ///
  /// In en, this message translates to:
  /// **'That count is no longer open.'**
  String get inventoryFailureCountMissing;

  /// The sentence behind "inventory.failure.countClosed".
  ///
  /// In en, this message translates to:
  /// **'This count is already finished.'**
  String get inventoryFailureCountClosed;

  /// The sentence behind "inventory.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'The load list could not be read.'**
  String get inventoryFailureMalformed;

  /// The sentence behind "messaging.thread.title".
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagingThreadTitle;

  /// The sentence behind "messaging.thread.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing said yet.'**
  String get messagingThreadEmpty;

  /// The sentence behind "messaging.thread.queued".
  ///
  /// In en, this message translates to:
  /// **'{count} waiting to send'**
  String messagingThreadQueued(int count);

  /// The sentence behind "messaging.status.queued".
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get messagingStatusQueued;

  /// The sentence behind "messaging.status.sent".
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messagingStatusSent;

  /// The sentence behind "messaging.status.read".
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get messagingStatusRead;

  /// The sentence behind "messaging.failure.threadUnavailable".
  ///
  /// In en, this message translates to:
  /// **'This conversation could not be opened.'**
  String get messagingFailureThread;

  /// The sentence behind "messaging.failure.deferred".
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection.'**
  String get messagingFailureDeferred;

  /// The sentence behind "messaging.failure.refused".
  ///
  /// In en, this message translates to:
  /// **'The operation would not take that message.'**
  String get messagingFailureRefused;

  /// The sentence behind "messaging.failure.missing".
  ///
  /// In en, this message translates to:
  /// **'That message is no longer here.'**
  String get messagingFailureMissing;

  /// The sentence behind "messaging.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'That message cannot be sent.'**
  String get messagingFailureMalformed;

  /// The sentence behind "documents.title".
  ///
  /// In en, this message translates to:
  /// **'Paperwork'**
  String get documentsTitle;

  /// The sentence behind "documents.share".
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get documentsShare;

  /// The sentence behind "documents.size".
  ///
  /// In en, this message translates to:
  /// **'{bytes} bytes'**
  String documentsSize(int bytes);

  /// The sentence behind "documents.kind.waybill".
  ///
  /// In en, this message translates to:
  /// **'Waybill'**
  String get documentsKindWaybill;

  /// The sentence behind "documents.kind.deliveryReceipt".
  ///
  /// In en, this message translates to:
  /// **'Delivery receipt'**
  String get documentsKindReceipt;

  /// The sentence behind "documents.kind.damageReport".
  ///
  /// In en, this message translates to:
  /// **'Damage report'**
  String get documentsKindDamageReport;

  /// The sentence behind "documents.failure.renderFailed".
  ///
  /// In en, this message translates to:
  /// **'This document could not be produced. Try again.'**
  String get documentsFailureRender;

  /// The sentence behind "documents.failure.refused".
  ///
  /// In en, this message translates to:
  /// **'The operation will not produce it: {reason}'**
  String documentsFailureRefused(String reason);

  /// The sentence behind "documents.failure.archiveUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The stored copy could not be read.'**
  String get documentsFailureArchive;

  /// The sentence behind "documents.failure.missing".
  ///
  /// In en, this message translates to:
  /// **'That document is no longer stored.'**
  String get documentsFailureMissing;

  /// The sentence behind "documents.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'That document could not be read.'**
  String get documentsFailureMalformed;
}

class _PeykCourierLocalizationsDelegate
    extends LocalizationsDelegate<PeykCourierLocalizations> {
  const _PeykCourierLocalizationsDelegate();

  @override
  Future<PeykCourierLocalizations> load(Locale locale) {
    return SynchronousFuture<PeykCourierLocalizations>(
      lookupPeykCourierLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_PeykCourierLocalizationsDelegate old) => false;
}

PeykCourierLocalizations lookupPeykCourierLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PeykCourierLocalizationsEn();
    case 'tr':
      return PeykCourierLocalizationsTr();
  }

  throw FlutterError(
    'PeykCourierLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
