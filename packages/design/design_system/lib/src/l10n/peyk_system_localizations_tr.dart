// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_system_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class PeykSystemLocalizationsTr extends PeykSystemLocalizations {
  PeykSystemLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get retry => 'Tekrar dene';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get empty => 'Burada henüz bir şey yok';

  @override
  String get dismiss => 'Kapat';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count okunmamış',
      one: '1 okunmamış',
      zero: 'Okunmamış yok',
    );
    return '$_temp0';
  }

  @override
  String get selected => 'Seçili';
}
