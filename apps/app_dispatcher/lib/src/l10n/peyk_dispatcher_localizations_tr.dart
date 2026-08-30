// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_dispatcher_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class PeykDispatcherLocalizationsTr extends PeykDispatcherLocalizations {
  PeykDispatcherLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get identitySignInTitle => 'Giriş yap';

  @override
  String get identitySignInIdle => 'Panoyu açmak için giriş yap.';

  @override
  String get identitySignInPending => 'Giriş yapılıyor';

  @override
  String identitySignedInAs(String name) {
    return '$name olarak giriş yapıldı';
  }

  @override
  String get identityFailureRejected =>
      'Bu bilgiler geçmedi. Kontrol edip tekrar dene.';

  @override
  String get identityFailureDeviceChanged =>
      'Bu istasyon değişmiş. Tekrar giriş yap.';

  @override
  String get identityFailureSessionEnded =>
      'Oturumun sona erdi. Tekrar giriş yap.';

  @override
  String get identityFailureDisabled =>
      'Bu hesap aktif değil. Yöneticiye başvur.';

  @override
  String get identityFailureUnavailable =>
      'Kimlik servisi yanıt vermedi. Tekrar dene.';

  @override
  String get identityFailureInternal => 'Girişte bir sorun oldu. Depoyu ara.';

  @override
  String get shipmentsStatusAwaitingAssignment => 'Atanmadı';

  @override
  String get shipmentsStatusAssignedToCourier => 'Atandı';

  @override
  String get shipmentsStatusLoadedOnVehicle => 'Araçta';

  @override
  String get shipmentsStatusOutForDelivery => 'Dağıtımda';

  @override
  String get shipmentsStatusDelivered => 'Teslim edildi';

  @override
  String get shipmentsStatusUndeliverable => 'Teslim edilemedi';

  @override
  String get shipmentsStatusReturned => 'Depoya döndü';

  @override
  String get routingTitle => 'Kurye rotası';

  @override
  String get routingUnplanned => 'Bu kuryeye henüz rota planlanmadı.';

  @override
  String get routingNothingToDrive => 'Bu kuryenin bugün gideceği durak yok.';

  @override
  String routingSummary(int stops, DateTime finishesAt) {
    final intl.DateFormat finishesAtDateFormat = intl.DateFormat.Hm(localeName);
    final String finishesAtString = finishesAtDateFormat.format(finishesAt);

    return '$stops durak, dönüş $finishesAtString';
  }

  @override
  String routingStopArrivesAt(DateTime arrivesAt) {
    final intl.DateFormat arrivesAtDateFormat = intl.DateFormat.Hm(localeName);
    final String arrivesAtString = arrivesAtDateFormat.format(arrivesAt);

    return 'Varış $arrivesAtString';
  }

  @override
  String get routingStopNext => 'Sıradaki';

  @override
  String get routingStopLate => 'Gecikmeli';

  @override
  String get routingStopDone => 'Tamam';

  @override
  String get routingStopArrived => 'Varış işaretle';

  @override
  String get routingStopMoveUp => 'Yukarı al';

  @override
  String get routingFailureNoPlan => 'Bu kuryeye henüz rota planlanmadı.';

  @override
  String get routingFailureSequenceMismatch => 'Bu sıralama bu rotaya uymuyor.';

  @override
  String get routingFailureUnsatisfiable => 'Bu durakların hepsi sığmıyor.';

  @override
  String routingFailureNotGeocoded(String address) {
    return 'Bir durağın konumu yok: $address';
  }

  @override
  String get routingFailurePositionUnavailable =>
      'Konum bildirilmedi. Rota planlandığı gibi.';

  @override
  String get routingFailurePlannerUnavailable =>
      'Çözücü yanıt vermedi. Bu, döndürdüğü son rota.';

  @override
  String routingFailureMalformed(String field) {
    return '$field alanında bir sorun var.';
  }

  @override
  String get paymentsTitle => 'Tahsilat';

  @override
  String get paymentsNothingOwed => 'Bu gönderide tahsilat yok.';

  @override
  String paymentsOwed(int minorUnits, String currency, int scale) {
    return 'Tahsil edilecek $minorUnits $currency';
  }

  @override
  String paymentsTaken(int minorUnits, String currency, int scale) {
    return '$minorUnits $currency alındı';
  }

  @override
  String paymentsTakingBy(String method) {
    return '$method ile alınıyor';
  }

  @override
  String get paymentsMethodCash => 'Nakit';

  @override
  String get paymentsMethodCard => 'Kart';

  @override
  String get paymentsCollect => 'Ödemeyi kaydet';

  @override
  String paymentsFailureRefused(String reason) {
    return 'Reddedildi: $reason';
  }

  @override
  String get paymentsFailureCashDrawer => 'Nakit kaydı güncellenemedi.';

  @override
  String get paymentsFailureUnavailable => 'Ödeme servisi yanıt vermedi.';

  @override
  String get paymentsFailureAlreadySettled => 'Bu ödeme zaten alınmış.';

  @override
  String get paymentsFailureNothingToCollect => 'Bu gönderide tahsilat yok.';

  @override
  String paymentsFailureRefundNotPossible(String reason) {
    return 'İade edilemez: $reason';
  }

  @override
  String get paymentsFailureSettlementUnavailable =>
      'Günlük toplamın okunamadı.';

  @override
  String get paymentsFailureSettlementClosed => 'Günün zaten teslim edilmiş.';

  @override
  String paymentsFailureCurrencyMismatch(int expected, String actual) {
    return 'Bu $actual cinsinden, tahsilat $expected cinsinden.';
  }

  @override
  String paymentsFailureMalformed(String field) {
    return '$field alanında bir sorun var.';
  }

  @override
  String get syncReviewTitle => 'Takılan işler';

  @override
  String get syncReviewEmpty => 'Karar bekleyen bir şey yok.';

  @override
  String get syncReviewRetry => 'Tekrar dene';

  @override
  String syncReviewAttempts(int count) {
    return '$count deneme';
  }

  @override
  String get syncStatusIdle => 'Her şey gönderildi';

  @override
  String syncStatusDraining(int count) {
    return '$count gönderiliyor';
  }

  @override
  String syncStatusWaitingForNetwork(int count) {
    return '$count servisi bekliyor';
  }

  @override
  String syncStatusWaitingToRetry(int count) {
    return '$count tekrar denenecek';
  }

  @override
  String syncStatusBlocked(int count) {
    return '$count seni bekliyor';
  }

  @override
  String get syncFailureOffline =>
      'Servis yanıt vermedi. Bu liste eski olabilir.';

  @override
  String get syncFailureOutboxUnavailable => 'Kuyruk okunamadı.';

  @override
  String get syncFailureOther => 'Bir sorun oldu. Tekrar dene.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageSection => 'Dil';

  @override
  String get settingsThemeSection => 'Görünüm';

  @override
  String get settingsSyncSection => 'Kuryeler ne zaman göndersin';

  @override
  String get settingsSignOut => 'Oturumu kapat';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsThemeSystem => 'Telefonu takip et';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsSyncAlways => 'Her zaman';

  @override
  String get settingsSyncUnmeteredOnly => 'Sadece Wi-Fi\'da';

  @override
  String get settingsSyncManual => 'Sadece ben söyleyince';

  @override
  String get settingsFailureUnavailable => 'Ayarlarına ulaşılamadı.';

  @override
  String get settingsFailureCorrupted => 'Ayarların okunamadı.';

  @override
  String settingsFailureMalformed(String field) {
    return 'Bu $field kullanılamaz.';
  }

  @override
  String get notificationsInboxTitle => 'Operasyon bildirimleri';

  @override
  String get notificationsInboxEmpty => 'Sahadan bir şey yok.';

  @override
  String get notificationsFailureUnavailable => 'Bildirimlerin okunamadı.';

  @override
  String get notificationsFailureMissing => 'Bu bildirim artık yok.';

  @override
  String get notificationsFailureRefused => 'Masada bildirim yok. Buradan oku.';

  @override
  String get notificationsFailureBlocked => 'Masada bildirim yok. Buradan oku.';

  @override
  String get notificationsFailureUnreachable => 'Masada bildirim yok.';

  @override
  String get notificationsFailureMalformed => 'Bir bildirim okunamadı.';

  @override
  String get incidentsBoardTitle => 'Açık sorunlar';

  @override
  String get incidentsBoardClear => 'Operasyonda açık sorun yok.';

  @override
  String get incidentsCategoryDamage => 'Hasarlı';

  @override
  String get incidentsCategoryAddressNotFound => 'Adres bulunamadı';

  @override
  String get incidentsCategoryRecipientUnavailable => 'Kimse yok';

  @override
  String get incidentsCategoryAccessDenied => 'İçeri girilemedi';

  @override
  String get incidentsCategoryFieldEmergency => 'Acil durum';

  @override
  String get incidentsCategoryUnclassified => 'Diğer';

  @override
  String get incidentsSeverityRoutine => 'Rutin';

  @override
  String get incidentsSeverityUrgent => 'Acil';

  @override
  String get incidentsSeverityCritical => 'Kritik';

  @override
  String get incidentsFailureLogUnavailable => 'Sorun listesi okunamadı.';

  @override
  String get incidentsFailureMissing => 'Bu sorun artık açık değil.';

  @override
  String incidentsFailureNotInState(String attempted) {
    return 'Bu şu anda $attempted yapılamaz.';
  }

  @override
  String incidentsFailureMalformed(String field) {
    return '$field alanında bir sorun var.';
  }

  @override
  String get messagingThreadTitle => 'Konuşma';

  @override
  String get messagingThreadEmpty => 'Henüz bir şey yazılmadı.';

  @override
  String messagingThreadQueued(int count) {
    return '$count gönderilmeyi bekliyor';
  }

  @override
  String get messagingStatusQueued => 'Bekliyor';

  @override
  String get messagingStatusSent => 'Gönderildi';

  @override
  String get messagingStatusRead => 'Okundu';

  @override
  String get messagingFailureThread => 'Bu konuşma açılamadı.';

  @override
  String get messagingFailureDeferred => 'Bağlantı bekleniyor.';

  @override
  String get messagingFailureRefused => 'Servis bu mesajı kabul etmedi.';

  @override
  String get messagingFailureMissing => 'Bu mesaj artık yok.';

  @override
  String get messagingFailureMalformed => 'Bu mesaj gönderilemez.';

  @override
  String get shipmentsDispatcherTitle => 'Pano';

  @override
  String get shipmentsDispatcherEmpty => 'Panoda bir şey yok.';

  @override
  String shipmentsDispatcherBulkAssign(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gönderi ata',
      zero: 'Ata',
    );
    return '$_temp0';
  }

  @override
  String get shipmentsDispatcherFailureUnavailable => 'Pano yüklenemedi.';

  @override
  String get reportsTitle => 'Gün';

  @override
  String get reportsForbidden => 'Bu rapor sana açık değil.';

  @override
  String get reportsTotalsSection => 'Toplamlar';

  @override
  String reportsTotal(int count) {
    return '$count gönderi';
  }

  @override
  String reportsDelivered(int count) {
    return '$count teslim edildi';
  }

  @override
  String get reportsDaysSection => 'Güne göre';

  @override
  String reportsDayRate(String day, int rate) {
    return '%$rate';
  }

  @override
  String get reportsFailureTally => 'Rakamlar okunamadı.';

  @override
  String get reportsFailureRange => 'Bu aralık bitişten sonra başlıyor.';

  @override
  String get reportsFailureMalformed =>
      'Kayıtlı rakamların bir kısmı okunamadı.';
}
