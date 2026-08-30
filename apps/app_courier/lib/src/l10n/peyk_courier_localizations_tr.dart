// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'peyk_courier_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class PeykCourierLocalizationsTr extends PeykCourierLocalizations {
  PeykCourierLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get identitySignInTitle => 'Giriş yap';

  @override
  String get identitySignInIdle => 'Turuna başlamak için giriş yap.';

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
      'Bu telefon değişmiş. Kaydetmek için tekrar giriş yap.';

  @override
  String get identityFailureSessionEnded =>
      'Oturumun sona erdi. Tekrar giriş yap.';

  @override
  String get identityFailureDisabled => 'Bu hesap aktif değil. Depoyu ara.';

  @override
  String get identityFailureUnavailable => 'Sinyal yok. Birazdan tekrar dene.';

  @override
  String get identityFailureInternal => 'Girişte bir sorun oldu. Depoyu ara.';

  @override
  String get shipmentsCourierTitle => 'Duraklarım';

  @override
  String get shipmentsCourierEmpty => 'Sana henüz bir şey atanmadı.';

  @override
  String get shipmentsCourierFailureUnavailable =>
      'Sinyal yok. Telefondakiler gösteriliyor.';

  @override
  String get shipmentsCourierFailureNotFound =>
      'Bu gönderi artık operasyonda değil.';

  @override
  String get shipmentsCourierFailureOther => 'Bir sorun oldu. Tekrar dene.';

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
  String get routingTitle => 'Rotam';

  @override
  String get routingUnplanned => 'Sana henüz rota planlanmadı.';

  @override
  String get routingNothingToDrive => 'Bugün gidilecek durak yok.';

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
  String get routingStopArrived => 'Geldim';

  @override
  String get routingStopMoveUp => 'Yukarı al';

  @override
  String get routingFailureNoPlan => 'Sana henüz rota planlanmadı.';

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
      'Konum yok. Rota planlandığı gibi gösteriliyor.';

  @override
  String get routingFailurePlannerUnavailable =>
      'Planlayıcıya ulaşılamadı. Bu rota telefondan.';

  @override
  String routingFailureMalformed(String field) {
    return '$field alanında bir sorun var.';
  }

  @override
  String get deliveryTitle => 'Kapıda';

  @override
  String deliveryDelivering(String shipment) {
    return '$shipment teslim ediliyor';
  }

  @override
  String get deliveryRecipientLabel => 'Teslim alan';

  @override
  String get deliveryRecipientHint => 'Kapıdaki kişinin adı';

  @override
  String deliveryStillNeeded(String kinds) {
    return 'Hâlâ gerekli: $kinds';
  }

  @override
  String deliveryCaptured(String kind) {
    return 'Alındı: $kind';
  }

  @override
  String get deliveryAddSignature => 'İmza al';

  @override
  String get deliveryAddPhoto => 'Fotoğraf çek';

  @override
  String get deliveryDelivered => 'Teslim ettim';

  @override
  String get deliveryCouldNotDeliver => 'Teslim edemedim';

  @override
  String get deliveryRecorded => 'Kaydedildi.';

  @override
  String get deliveryEvidenceSignature => 'imza';

  @override
  String get deliveryEvidencePhoto => 'fotoğraf';

  @override
  String get deliveryEvidenceScan => 'okutma';

  @override
  String deliveryFailureOutsideArea(int metres) {
    return 'Adrese ${metres}m uzaktasın.';
  }

  @override
  String get deliveryFailurePositionUnavailable =>
      'Konumun okunamadı. Dışarı çıkıp tekrar dene.';

  @override
  String deliveryFailureProofInsufficient(String kinds) {
    return 'Bu gönderi için $kinds gerekiyor.';
  }

  @override
  String get deliveryFailureAlreadySettled => 'Bu ziyaret zaten kaydedilmiş.';

  @override
  String get deliveryFailureProofStore => 'Kanıt kaydedilemedi.';

  @override
  String get deliveryFailureProofNotFound => 'Bu kanıt telefonda yok.';

  @override
  String get deliveryFailureMediaTooLarge =>
      'Bu fotoğraf çok büyük. Yenisini çek.';

  @override
  String get deliveryFailureUnavailable => 'Sıraya alınamadı. Tekrar dene.';

  @override
  String deliveryFailureMalformed(String field) {
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
  String get paymentsCollect => 'Ödemeyi al';

  @override
  String get paymentsDone => 'Bitir';

  @override
  String paymentsFailureRefused(String reason) {
    return 'Reddedildi: $reason';
  }

  @override
  String get paymentsFailureCashDrawer => 'Nakit kaydı güncellenemedi.';

  @override
  String get paymentsFailureUnavailable => 'Kaydedilemedi. Tekrar dene.';

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
  String get syncReviewEmpty => 'Seni bekleyen bir şey yok.';

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
    return '$count sinyal bekliyor';
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
  String get syncFailureOffline => 'Sinyal yok. Bu liste telefondan.';

  @override
  String get syncFailureOutboxUnavailable => 'Telefondaki kuyruk okunamadı.';

  @override
  String get syncFailureOther => 'Bir sorun oldu. Tekrar dene.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageSection => 'Dil';

  @override
  String get settingsThemeSection => 'Görünüm';

  @override
  String get settingsSyncSection => 'Ne zaman gönderilsin';

  @override
  String get settingsSignOut => 'Çıkış yap';

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
  String get notificationsInboxTitle => 'Bildirimler';

  @override
  String get notificationsInboxEmpty => 'Operasyondan bir şey yok.';

  @override
  String get notificationsFailureUnavailable => 'Bildirimlerin okunamadı.';

  @override
  String get notificationsFailureMissing => 'Bu bildirim artık yok.';

  @override
  String get notificationsFailureRefused =>
      'Bildirimler kapalı. İş haberi almak için aç.';

  @override
  String get notificationsFailureBlocked =>
      'Bildirimler telefon ayarlarında engellenmiş.';

  @override
  String get notificationsFailureUnreachable =>
      'Bu telefon bildirimlere kaydedilemedi.';

  @override
  String get notificationsFailureMalformed => 'Bir bildirim okunamadı.';

  @override
  String get incidentsBoardTitle => 'Sorunlar';

  @override
  String get incidentsBoardClear => 'Açık sorun yok.';

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
  String get inventoryTitle => 'Aracı say';

  @override
  String get inventoryIdle =>
      'Açık sayım yok. Yükleme veya boşaltma için başlat.';

  @override
  String get inventoryPreparing => 'Yükleme listesi alınıyor';

  @override
  String inventoryProgress(int scanned, int expected) {
    return '$expected parçadan $scanned';
  }

  @override
  String inventoryMissing(int count) {
    return '$count eksik';
  }

  @override
  String inventoryUnexpected(int count) {
    return '$count listede yok';
  }

  @override
  String get inventoryReconciled => 'Hepsi tamam';

  @override
  String get inventoryFailureManifest => 'Yükleme listesine ulaşılamadı.';

  @override
  String get inventoryFailureCount => 'Bu sayım kaydedilemedi.';

  @override
  String get inventoryFailureCountMissing => 'Bu sayım artık açık değil.';

  @override
  String get inventoryFailureCountClosed => 'Bu sayım zaten bitmiş.';

  @override
  String get inventoryFailureMalformed => 'Yükleme listesi okunamadı.';

  @override
  String get messagingThreadTitle => 'Mesajlar';

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
  String get messagingFailureRefused => 'Operasyon bu mesajı kabul etmedi.';

  @override
  String get messagingFailureMissing => 'Bu mesaj artık yok.';

  @override
  String get messagingFailureMalformed => 'Bu mesaj gönderilemez.';

  @override
  String get documentsTitle => 'Evrak';

  @override
  String get documentsShare => 'Paylaş';

  @override
  String documentsSize(int bytes) {
    return '$bytes bayt';
  }

  @override
  String get documentsKindWaybill => 'İrsaliye';

  @override
  String get documentsKindReceipt => 'Teslim makbuzu';

  @override
  String get documentsKindDamageReport => 'Hasar raporu';

  @override
  String get documentsFailureRender => 'Bu belge üretilemedi. Tekrar dene.';

  @override
  String documentsFailureRefused(String reason) {
    return 'Operasyon üretmiyor: $reason';
  }

  @override
  String get documentsFailureArchive => 'Saklanan kopya okunamadı.';

  @override
  String get documentsFailureMissing => 'Bu belge artık saklanmıyor.';

  @override
  String get documentsFailureMalformed => 'Bu belge okunamadı.';
}
