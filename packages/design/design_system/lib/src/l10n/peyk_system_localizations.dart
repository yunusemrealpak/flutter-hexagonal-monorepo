import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'peyk_system_localizations_en.dart';
import 'peyk_system_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PeykSystemLocalizations
/// returned by `PeykSystemLocalizations.of(context)`.
///
/// Applications need to include `PeykSystemLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/peyk_system_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PeykSystemLocalizations.localizationsDelegates,
///   supportedLocales: PeykSystemLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the PeykSystemLocalizations.supportedLocales
/// property.
abstract class PeykSystemLocalizations {
  PeykSystemLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PeykSystemLocalizations of(BuildContext context) {
    return Localizations.of<PeykSystemLocalizations>(
      context,
      PeykSystemLocalizations,
    )!;
  }

  static const LocalizationsDelegate<PeykSystemLocalizations> delegate =
      _PeykSystemLocalizationsDelegate();

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

  /// The action on a failure view. Ships with the component rather than with each caller, because fourteen presentation packages would otherwise each supply their own spelling of it.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// The accessible label of the loading indicator. Read aloud, so it is a word rather than an ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// The default line on an empty view, used when a caller has nothing more specific to say.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get empty;

  /// The action that closes a banner or a sheet.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// The accessible label of a count badge. A plural rather than a number with a word after it, because Turkish and English disagree about what happens to the noun.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread} =1{1 unread} other{{count} unread}}'**
  String unreadCount(int count);

  /// Takes back what somebody has drawn or entered, without leaving the surface they are on. Ships with the component for the same reason the retry does.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Finishes a capture and hands what was captured back to the screen that asked for it.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Leaves a capture with nothing captured. Distinct from `dismiss`, which closes something that was only telling you a thing.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// The accessible label of the drawing surface. It says how to use it because a blank rectangle announces nothing at all to a screen reader, and the gesture is the whole control.
  ///
  /// In en, this message translates to:
  /// **'Signature area. Draw with one finger.'**
  String get signatureArea;

  /// Announced for the chosen option in a group. The visual mark alone is not available to a screen reader.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;
}

class _PeykSystemLocalizationsDelegate
    extends LocalizationsDelegate<PeykSystemLocalizations> {
  const _PeykSystemLocalizationsDelegate();

  @override
  Future<PeykSystemLocalizations> load(Locale locale) {
    return SynchronousFuture<PeykSystemLocalizations>(
      lookupPeykSystemLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_PeykSystemLocalizationsDelegate old) => false;
}

PeykSystemLocalizations lookupPeykSystemLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PeykSystemLocalizationsEn();
    case 'tr':
      return PeykSystemLocalizationsTr();
  }

  throw FlutterError(
    'PeykSystemLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
