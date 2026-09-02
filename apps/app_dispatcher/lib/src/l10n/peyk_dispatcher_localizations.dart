import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'peyk_dispatcher_localizations_en.dart';
import 'peyk_dispatcher_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PeykDispatcherLocalizations
/// returned by `PeykDispatcherLocalizations.of(context)`.
///
/// Applications need to include `PeykDispatcherLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/peyk_dispatcher_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PeykDispatcherLocalizations.localizationsDelegates,
///   supportedLocales: PeykDispatcherLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the PeykDispatcherLocalizations.supportedLocales
/// property.
abstract class PeykDispatcherLocalizations {
  PeykDispatcherLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PeykDispatcherLocalizations of(BuildContext context) {
    return Localizations.of<PeykDispatcherLocalizations>(
      context,
      PeykDispatcherLocalizations,
    )!;
  }

  static const LocalizationsDelegate<PeykDispatcherLocalizations> delegate =
      _PeykDispatcherLocalizationsDelegate();

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
  /// **'Sign in to open the board.'**
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
  /// **'This workstation has changed. Sign in again.'**
  String get identityFailureDeviceChanged;

  /// The sentence behind "identity.failure.sessionEnded".
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get identityFailureSessionEnded;

  /// The sentence behind "identity.failure.disabled".
  ///
  /// In en, this message translates to:
  /// **'This account is not active. Ask an administrator.'**
  String get identityFailureDisabled;

  /// The sentence behind "identity.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'The identity service did not answer. Try again.'**
  String get identityFailureUnavailable;

  /// The sentence behind "identity.failure.internal".
  ///
  /// In en, this message translates to:
  /// **'Something went wrong signing you in. Call the depot.'**
  String get identityFailureInternal;

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
  /// **'Courier route'**
  String get routingTitle;

  /// The sentence behind "routing.unplanned".
  ///
  /// In en, this message translates to:
  /// **'No route has been planned for this courier yet.'**
  String get routingUnplanned;

  /// The sentence behind "routing.nothingToDrive".
  ///
  /// In en, this message translates to:
  /// **'This courier has nothing to drive today.'**
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
  /// **'Mark arrived'**
  String get routingStopArrived;

  /// The sentence behind "routing.stop.moveUp".
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get routingStopMoveUp;

  /// The sentence behind "routing.failure.noPlan".
  ///
  /// In en, this message translates to:
  /// **'No route has been planned for this courier yet.'**
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
  /// **'No position reported. This is the route as planned.'**
  String get routingFailurePositionUnavailable;

  /// The sentence behind "routing.failure.plannerUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The solver did not answer. This route is the last one it returned.'**
  String get routingFailurePlannerUnavailable;

  /// The sentence behind "routing.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with {field}.'**
  String routingFailureMalformed(String field);

  /// The sentence behind "payments.title".
  ///
  /// In en, this message translates to:
  /// **'Collection'**
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
  /// **'Record payment'**
  String get paymentsCollect;

  /// The sentence behind "payments.done".
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paymentsDone;

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
  /// **'The payments service did not answer.'**
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
  /// **'Nothing needs a decision.'**
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
  /// **'{count} waiting for the service'**
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
  /// **'The service did not answer. This list may be stale.'**
  String get syncFailureOffline;

  /// The sentence behind "sync.failure.outboxUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The queue could not be read.'**
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
  /// **'When couriers send'**
  String get settingsSyncSection;

  /// The sentence behind "settings.alerts.section".
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsAlertsSection;

  /// The sentence behind "settings.alerts.explanation".
  ///
  /// In en, this message translates to:
  /// **'Notifications about assignments and route changes on this device.'**
  String get settingsAlertsExplanation;

  /// The sentence behind "settings.alerts.toggle".
  ///
  /// In en, this message translates to:
  /// **'Alerts on this device'**
  String get settingsAlertsToggle;

  /// The sentence behind "settings.alerts.blocked".
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled for this application in the system settings.'**
  String get settingsAlertsBlocked;

  /// The sentence behind "settings.alerts.openSettings".
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get settingsAlertsOpenSettings;

  /// The sentence behind "settings.alerts.failure.refused".
  ///
  /// In en, this message translates to:
  /// **'Alerts were not enabled.'**
  String get settingsAlertsFailureRefused;

  /// The sentence behind "settings.alerts.failure.unreachable".
  ///
  /// In en, this message translates to:
  /// **'This device could not be registered for alerts.'**
  String get settingsAlertsFailureUnreachable;

  /// The sentence behind "settings.alerts.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'The alert state could not be read.'**
  String get settingsAlertsFailureUnavailable;

  /// The sentence behind "settings.signOut".
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

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
  /// **'Operation notices'**
  String get notificationsInboxTitle;

  /// The sentence behind "notifications.inbox.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing from the field.'**
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
  /// **'Alerts are not available at a desk. Read them here instead.'**
  String get notificationsFailureRefused;

  /// The sentence behind "notifications.failure.blocked".
  ///
  /// In en, this message translates to:
  /// **'Alerts are not available at a desk. Read them here instead.'**
  String get notificationsFailureBlocked;

  /// The sentence behind "notifications.failure.unreachable".
  ///
  /// In en, this message translates to:
  /// **'Alerts are not available at a desk.'**
  String get notificationsFailureUnreachable;

  /// The sentence behind "notifications.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'An alert could not be read.'**
  String get notificationsFailureMalformed;

  /// The sentence behind "incidents.board.title".
  ///
  /// In en, this message translates to:
  /// **'Open problems'**
  String get incidentsBoardTitle;

  /// The sentence behind "incidents.board.clear".
  ///
  /// In en, this message translates to:
  /// **'Nothing open across the operation.'**
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

  /// The sentence behind "messaging.thread.title".
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
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
  /// **'The service would not take that message.'**
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

  /// The sentence behind "shipments.dispatcher.title".
  ///
  /// In en, this message translates to:
  /// **'The board'**
  String get shipmentsDispatcherTitle;

  /// The sentence behind "shipments.dispatcher.empty".
  ///
  /// In en, this message translates to:
  /// **'Nothing on the board.'**
  String get shipmentsDispatcherEmpty;

  /// The sentence behind "shipments.dispatcher.loadMore". The tail of the board, when there are more pages.
  ///
  /// In en, this message translates to:
  /// **'Load more parcels'**
  String get shipmentsDispatcherLoadMore;

  /// The sentence behind "shipments.dispatcher.moreFailed". Shown beside the board, which keeps its rows and its ticks.
  ///
  /// In en, this message translates to:
  /// **'The next parcels did not load.'**
  String get shipmentsDispatcherMoreFailed;

  /// The sentence behind "shipments.dispatcher.bulkAssign".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Assign} =1{Assign 1 parcel} other{Assign {count} parcels}}'**
  String shipmentsDispatcherBulkAssign(int count);

  /// The sentence behind "shipments.dispatcher.failure.unavailable".
  ///
  /// In en, this message translates to:
  /// **'The board could not be loaded.'**
  String get shipmentsDispatcherFailureUnavailable;

  /// The sentence behind "reports.title".
  ///
  /// In en, this message translates to:
  /// **'The day'**
  String get reportsTitle;

  /// The sentence behind "reports.forbidden".
  ///
  /// In en, this message translates to:
  /// **'This report is not yours to read.'**
  String get reportsForbidden;

  /// The sentence behind "reports.totals.section".
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get reportsTotalsSection;

  /// The sentence behind "reports.total".
  ///
  /// In en, this message translates to:
  /// **'{count} shipments'**
  String reportsTotal(int count);

  /// The sentence behind "reports.delivered".
  ///
  /// In en, this message translates to:
  /// **'{count} delivered'**
  String reportsDelivered(int count);

  /// The sentence behind "reports.days.section".
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get reportsDaysSection;

  /// The sentence behind "reports.day.rate".
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String reportsDayRate(String day, int rate);

  /// The sentence behind "reports.failure.tallyUnavailable".
  ///
  /// In en, this message translates to:
  /// **'The figures could not be read.'**
  String get reportsFailureTally;

  /// The sentence behind "reports.failure.rangeInverted".
  ///
  /// In en, this message translates to:
  /// **'That range starts after it ends.'**
  String get reportsFailureRange;

  /// The sentence behind "reports.failure.malformed".
  ///
  /// In en, this message translates to:
  /// **'Some of the stored figures could not be read.'**
  String get reportsFailureMalformed;
}

class _PeykDispatcherLocalizationsDelegate
    extends LocalizationsDelegate<PeykDispatcherLocalizations> {
  const _PeykDispatcherLocalizationsDelegate();

  @override
  Future<PeykDispatcherLocalizations> load(Locale locale) {
    return SynchronousFuture<PeykDispatcherLocalizations>(
      lookupPeykDispatcherLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_PeykDispatcherLocalizationsDelegate old) => false;
}

PeykDispatcherLocalizations lookupPeykDispatcherLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PeykDispatcherLocalizationsEn();
    case 'tr':
      return PeykDispatcherLocalizationsTr();
  }

  throw FlutterError(
    'PeykDispatcherLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
