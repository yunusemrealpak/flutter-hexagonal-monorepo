// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_system_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PeykSystemLocalizationsEn extends PeykSystemLocalizations {
  PeykSystemLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading';

  @override
  String get empty => 'Nothing here yet';

  @override
  String get dismiss => 'Dismiss';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: 'No unread',
    );
    return '$_temp0';
  }

  @override
  String get clear => 'Clear';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get signatureArea => 'Signature area. Draw with one finger.';

  @override
  String get selected => 'Selected';
}
