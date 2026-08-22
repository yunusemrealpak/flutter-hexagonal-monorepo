# Proje Spec: flutter-hexagonal-monorepo

**Hexagonal mimarinin büyük ölçekli bir Flutter monorepo'sundaki referans uygulaması**

Bu doküman Claude Code'a verilecek görev tanımıdır. Baştan sona oku, sonra Faz 0'dan başla.

**GitHub deposu:** `flutter-hexagonal-monorepo`. Depo adı tanımlayıcıdır çünkü bu bir referans deposudur ve adının ne öğrettiğini tek bakışta söylemesi gerekir.

**Örnek ürün adı:** Peyk. Osmanlı'da sultanın yaya ulağı, yani haberi ve yükü taşıyan kişi. Deponun içindeki örnek uygulama bir kurye ve sevkiyat operasyonunu modellediği için bu ad kullanılır. Dokümantasyonda ve kod içinde ürüne Peyk denir, depoya ise adıyla atıf yapılır.

**Workspace paketi:** `peyk_workspace`
**Depo açıklaması:** Hexagonal architecture (ports and adapters) in a large-scale Flutter monorepo: 74 packages, three apps, enforced dependency rules, and a test suite built to scale

---

## 0. Rol ve amaç

Sen büyük ölçekli bir Flutter monorepo'sunu sıfırdan kuran bir principal mobile engineer'sın. Görevin, hexagonal mimarinin (ports and adapters) paket seviyesinde uygulandığı, yaklaşık 74 paketlik bir referans workspace üretmek.

Bu bir öğrenme referansıdır. Amaç çalışan bir ürün değil, mimarinin her kuralının fiziksel olarak görülebildiği, derlenebilen ve testleri geçen eksiksiz bir iskelet.

### Başarı kriterleri

Repo aşağıdakileri sağlamalı:

1. `dart analyze` tüm workspace'te sıfır hata, sıfır uyarı ile geçer.
2. `dart run tooling/arch_check/bin/arch_check.dart` sıfır ihlal raporlar.
3. Yazılan tüm testler geçer.
4. `dart run tooling/dep_graph/bin/dep_graph.dart` bağımlılık grafiğini üretir ve grafikte hiçbir döngü yoktur.
5. Her paketin kendi `pubspec.yaml` dosyası vardır ve bağımlılık listesi anayasaya birebir uyar.
6. Üretilmiş (generated) dosyalar repoya commit edilmiştir ve günceldir: `melos run gen` sonrası `git diff --exit-code` temiz çıkar.

### Başarı kriteri OLMAYANLAR

- Uygulamanın gerçek bir backend'e bağlanması gerekmiyor.
- Ekranların görsel olarak bitmiş olması gerekmiyor.
- Her use case'in tam iş mantığını içermesi gerekmiyor. Kritik olanlar dolu yazılır, geri kalanı imza ve akış olarak durur.
- iOS/Android build alınması gerekmiyor.

---

## 1. Ürün ve domain

**Peyk: kurumsal dağıtım ve saha operasyonları platformu.**

Bir lojistik firmasının hem sahadaki kuryelerini hem operasyon merkezini yöneten sistem. Üç uygulama aynı çekirdeği paylaşır:

- **app_courier**: Sahadaki kurye kullanır. Offline-first çalışır. Rotasını görür, duraklara gider, teslimat yapar, kapıda tahsilat alır, araç stoğunu sayar. Bağlantı koptuğunda çalışmaya devam eder, bağlantı gelince yaptığı her şeyi sunucuya aktarır.
- **app_dispatcher**: Operasyon merkezi kullanır. Sevkiyat atar, kuryeleri canlı izler, istisnaları yönetir, gün sonu raporlarını alır. Online-first çalışır.
- **app_harness**: Geliştirici aracı. Tüm feature'ları gerçek adapter'lar yerine fake adapter'larla ayağa kaldırır. Mimarinin adapter değiştirilebilirlik vaadinin kanıtıdır.

Bu üç uygulama aynı `_application` paketlerini kullanır, farklı adapter setleriyle birleştirilir.

---

## 2. Mimari anayasa

Bu bölüm tartışmaya kapalıdır. Her paketin pubspec'i bu tabloya uymak zorundadır.

### 2.1 Paket tipleri ve izinli bağımlılıklar

| Paket tipi | Sadece şunlara bağımlanabilir |
|---|---|
| `core_kernel` | hiçbir şey (saf Dart, üçüncü parti yok) |
| `core_ports` | `core_kernel` |
| `core_navigation` | `core_kernel` |
| `core_testing` | `core_kernel`, `core_ports`, `core_navigation` |
| `<feature>_api` | `core_kernel`, `core_ports`, diğer feature'ların yalnızca `_api` paketleri |
| `<feature>_application` | kendi `_api`'si, `core_kernel`, `core_ports`, diğer feature'ların yalnızca `_api` paketleri |
| `<feature>_infrastructure` | kendi `_api`'si, `core_kernel`, `core_ports`, `platform/*` |
| `<feature>_presentation*` | kendi `_api`'si, diğer feature'ların `_api` paketleri, `core_kernel`, `core_navigation`, `design_system` |
| `<feature>_testing` | kendi `_api`'si, `core_kernel`, `core_ports`, `core_testing` |
| `<feature>_core` (indirgenmiş bölmede) | kendi `_api`'si, `core_kernel`, `core_ports`, `platform/*`, diğer feature'ların `_api` paketleri |
| `platform/*` | `core_kernel`, `core_ports` |
| `design_tokens` | hiçbir şey (flutter hariç) |
| `design_system` | `design_tokens`, `core_kernel` |
| `tooling/*` | hiçbir ürün paketi |
| `apps/*` | her şey |

### 2.2 Değişmez kurallar

1. **Feature'lar birbirine yalnızca `_api` üzerinden dokunur.** Bir feature'ın `_application`, `_infrastructure` veya `_presentation` paketi başka bir feature tarafından asla import edilmez.
2. **`_application` ve `_infrastructure` birbirini görmez.** İkisini yalnızca app'teki composition root birleştirir.
3. **`_api` ve `_application` paketleri saf Dart'tır.** Pubspec'lerinde `flutter` SDK bağımlılığı bulunmaz. Bu kural test hızının temelidir ve ihlal edilemez.
4. **Port'lar `_api`'de tanımlanır, implementasyonlar dışarıda yaşar.** `_api` paketinde tek satır implementasyon bulunmaz.
5. **Her paket public yüzeyini tek bir barrel dosyasından verir.** Geri kalan her şey `lib/src/` altındadır. Başka bir paketten `package:x/src/...` import etmek yasaktır.
6. **Bağımlılık grafiğinde döngü yoktur.** İki feature birbirine ihtiyaç duyuyorsa çözüm karşılıklı `_api` bağımlılığıdır, ortak bir "shared" paketi açmak değildir.
7. **Servis locator yalnızca app katmanında kullanılır.** Paketlerin içinde `GetIt` veya benzeri global erişim yoktur, bağımlılıklar constructor'dan geçer.
8. **`DateTime.now()`, `Random()`, `Uuid()` doğrudan kullanılmaz.** Bunlar `core_ports` içindeki `Clock`, `RandomSource`, `IdGenerator` portlarından alınır. Bu, testlerin deterministik olmasının şartıdır.
9. **Port sınırlarından exception fırlatılmaz.** Tüm port metotları `Result<Success, Failure>` döner. Failure tipleri `sealed class` olarak ilgili `_api` paketinde tanımlanır.
10. **DTO domain'e sızmaz, entity dışarı sızmaz.** Çeviri `_infrastructure` içindeki mapper'larda yapılır.

---

## 3. Paket envanteri

Aşağıdaki yapıyı birebir kur. Paket adları düz ve benzersizdir, klasör hiyerarşisi paket adına yansımaz.

```
peyk_workspace/
├── pubspec.yaml                    # workspace kökü + melos konfigürasyonu
├── analysis_options.yaml
├── dart_test.yaml
├── lefthook.yml
├── CLAUDE.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPENDENCY_RULES.md
│   ├── TESTING.md
│   ├── CI_CD.md
│   └── dependency-graph.md         # dep_graph tarafından üretilir
├── apps/
│   ├── app_courier/
│   ├── app_dispatcher/
│   └── app_harness/
├── packages/
│   ├── core/
│   │   ├── core_kernel/
│   │   ├── core_ports/
│   │   ├── core_navigation/
│   │   └── core_testing/
│   ├── features/
│   │   ├── identity/
│   │   │   ├── identity_api/
│   │   │   ├── identity_application/
│   │   │   ├── identity_infrastructure/
│   │   │   ├── identity_presentation/
│   │   │   └── identity_testing/
│   │   ├── shipments/
│   │   │   ├── shipments_api/
│   │   │   ├── shipments_application/
│   │   │   ├── shipments_infrastructure/
│   │   │   ├── shipments_presentation_courier/
│   │   │   ├── shipments_presentation_dispatcher/
│   │   │   └── shipments_testing/
│   │   ├── routing/                # api, application, infrastructure, presentation, testing
│   │   ├── delivery/               # api, application, infrastructure, presentation, testing
│   │   ├── payments/               # api, application, infrastructure, presentation, testing
│   │   ├── sync/                   # api, application, infrastructure, presentation, testing
│   │   ├── vehicle_inventory/      # api, core, presentation
│   │   ├── messaging/              # api, core, presentation, testing
│   │   ├── incidents/              # api, core, presentation
│   │   ├── documents/              # api, core, presentation
│   │   ├── notifications/          # api, core, presentation
│   │   ├── reporting/              # api, core, presentation
│   │   └── settings/               # api, core, presentation
│   ├── platform/
│   │   ├── http_dio/
│   │   ├── storage_drift/
│   │   ├── secure_store/
│   │   ├── location_service/
│   │   ├── media_capture/
│   │   ├── connectivity_monitor/
│   │   ├── analytics_otel/
│   │   └── push_messaging/
│   └── design/
│       ├── design_tokens/
│       └── design_system/
└── tooling/
    ├── arch_check/
    ├── test_runner/
    ├── scaffold/
    └── dep_graph/
```

### Neden bazı feature'lar 5, bazıları 3 paket

Bu kasıtlıdır ve dokümante edilmelidir. Ağır feature'lar tam bölmeyi hak eder. Hafif feature'lar `_api`, `_core` (application ve infrastructure birlikte), `_presentation` şeklinde üç pakette başlar. `_api` her koşulda ayrıdır çünkü döngüleri çözen ve etkilenme alanını daraltan tek şey odur. `_testing` paketi yalnızca fake'i başka bir paket tarafından tüketilen feature'larda açılır.

`docs/ARCHITECTURE.md` içinde "bir feature ne zaman tam bölmeyi hak eder" başlığı altında bu kalibrasyonu açıkla.

---

## 4. Feature domain tanımları

Her feature için aşağıdaki içerik üretilecek. Entity'ler gerçek davranış taşımalı, anemik veri sınıfları olmamalı.

### 4.1 identity

**Entities / value objects:** `Actor`, `ActorId`, `Session`, `AccessToken`, `DeviceBinding`, `Role`, `Permission`, `PermissionSet`

**Inbound port:** `IdentityFacade`
- `signIn(Credentials)`, `signOut()`, `refreshSession()`, `Stream<Session?> sessionChanges()`

**Diğer feature'lara açılan port'lar (çok önemli):**
- `SessionReader`: mevcut oturumu okur
- `PermissionChecker`: `bool can(Permission)` sorusu

**Outbound port'lar:** `CredentialGateway`, `SessionStore`, `DeviceRegistry`

**İş kuralı örneği:** Token süresi dolmadan belirli bir eşik kaldığında otomatik yenileme; cihaz bağı bozulmuşsa oturumun geçersiz sayılması.

### 4.2 shipments

**Entities:** `Shipment`, `ShipmentId`, `Barcode`, `Consignee`, `AddressPoint`, `ShipmentStatus` (sealed), `StatusTransition`, `ShipmentSummary`

**Durum makinesi (kritik):** `created -> assigned -> loaded -> outForDelivery -> delivered | failed | returned`. Geçiş kuralları `Shipment` entity'sinin içinde yaşar, use case'te değil. Geçersiz geçiş `ShipmentFailure.invalidTransition` döner. Bu durum makinesi için kapsamlı test yaz, mimarinin domain zenginliğini gösteren yer burasıdır.

**Inbound port:** `ShipmentsFacade`

**Outbound port'lar:** `ShipmentGateway`, `ShipmentCache`, `BarcodeResolverPort`

**Domain event'leri:** `ShipmentDelivered`, `ShipmentFailed`, `ShipmentReturned`

**İki presentation paketi:** `shipments_presentation_courier` kurye için sade durak listesi ve barkod okutma akışı; `shipments_presentation_dispatcher` operasyon için filtrelenebilir tablo, toplu atama ve izin kontrollü aksiyonlar. Aynı `_api`'yi tüketen iki farklı driving adapter olduğunu göster.

### 4.3 routing

**Entities:** `RoutePlan`, `Stop`, `StopSequence`, `Eta`, `TravelWindow`, `RouteConstraint`, `ServiceTime`

**Inbound port:** `RoutingFacade`: `planRoute`, `resequence`, `nextStop`, `recalculateOnDeviation`

**Outbound port'lar:** `RouteOptimizerPort`, `TrafficDataPort`, `RouteCache`, `LocationStreamPort`

**Aynı porta iki implementasyon (kritik):** `routing_infrastructure` içinde `LocalHeuristicOptimizer` (cihaz üstü nearest-neighbor + 2-opt iyileştirme, offline çalışır) ve `RemoteSolverOptimizer` (sunucudaki çözücüye istek atar). İkisi de `RouteOptimizerPort` implemente eder ve `routing_testing` içindeki tek contract test kit'inden geçer. app_courier birincisini, app_dispatcher ikincisini bağlar.

### 4.4 delivery

**Entities:** `DeliveryAttempt`, `ProofOfDelivery`, `SignatureCapture`, `PhotoEvidence`, `ScanEvidence`, `NonDeliveryReason` (sealed), `Recipient`

**Inbound port:** `DeliveryFacade`: `startAttempt`, `completeWithProof`, `failWithReason`

**Outbound port'lar:** `ProofStorePort`, `DeliveryGateway`, `MediaCompressorPort`, `GeoFencePort`

**İş kuralı örneği:** Teslimat kanıtı zorunluluğu gönderi tipine göre değişir. Yüksek değerli gönderide imza artı fotoğraf zorunlu, standart gönderide biri yeterli. Bu kural `_api` içindeki bir policy nesnesinde yaşar.

### 4.5 payments

**Entities:** `CollectionRequest`, `Money`, `Currency`, `PaymentMethod` (sealed: cash, card, transfer), `IdempotencyKey`, `PaymentAttempt`, `Settlement`, `PaymentFailure` (sealed)

**Inbound port:** `PaymentsFacade`: `collectOnDelivery`, `refund`, `closeDailySettlement`, `paymentStatusOf(ShipmentId)`

**Outbound port'lar:** `PaymentsGateway`, `CashDrawerPort`, `ReceiptPrinterPort`, `SettlementStore`

**Idempotency (kritik):** `IdempotencyKey`, use case içinde `IdGenerator` portundan üretilir ve kullanıcının tek bir ödeme niyetine bağlanır. Aynı niyetin tüm yeniden denemeleri aynı anahtarı taşır. Bu davranış için açık test yaz: aynı anahtarla iki kez çağrılan gateway'in tek işlem ürettiğini doğrula.

### 4.6 sync

Bu feature mimarinin en öğretici parçasıdır. Hiçbir feature'ı tanımadan hepsinin yazma işlemlerini taşır.

**Entities:** `OutboxEntry`, `SyncEnvelope`, `SyncCursor`, `ConflictPolicy` (sealed: lastWriteWins, serverWins, manualReview), `SyncStatus`, `RetrySchedule`

**Feature'lara açılan sözleşme:** `sync_api` içinde `SyncCommand` arayüzü. Her feature kendi komutunu bu arayüzü implemente ederek tanımlar (`CompleteDeliveryCommand`, `CollectPaymentCommand`, `ReportIncidentCommand`). Komut kendini bir `type` string'i ve serileştirilmiş payload olarak ifade eder.

**Inbound port:** `SyncFacade`: `enqueue(SyncCommand)`, `drain()`, `Stream<SyncStatus> statusChanges()`

**Outbound port'lar:** `OutboxStore`, `CommandTransportPort`, `ClockSkewPort`

**Composition root sorumluluğu:** Komut tipi ile taşıma handler'ını eşleyen registry app'te kurulur. `sync_application` yalnızca generic zarfları görür, `payments` veya `delivery` isimlerini hiç bilmez. Bu tersine çevirmeyi `docs/ARCHITECTURE.md` içinde ayrı başlık olarak anlat.

**Yeniden deneme politikası:** Üstel geri çekilme, kalıcı hata ile geçici hatanın ayrılması, kalıcı hatada manual review kuyruğuna düşürme.

### 4.7 Hafif feature'lar

Bunlar üç paketle kurulur, domain yüzeyleri daha dar tutulur ama aynı kurallara uyar:

- **vehicle_inventory**: Araç içi yük sayımı, yükleme ve boşaltma mutabakatı, eksik yük tespiti
- **messaging**: Kurye ile operasyon arası mesajlaşma, okundu bilgisi, offline kuyruk
- **incidents**: Hasar, adres bulunamadı, alıcı yok gibi istisnaların kaydı ve eskalasyonu
- **documents**: İrsaliye ve teslim belgesi üretimi, paylaşma
- **notifications**: Push ve uygulama içi bildirim kutusu
- **reporting**: Operasyon metrikleri, yalnızca dispatcher'da görünür
- **settings**: Kullanıcı tercihleri, dil, tema, senkronizasyon davranışı

---

## 5. Mimariyi sınayan senaryolar

Bunlar spec'in kalbidir. Her biri kodda görünür olmalı ve `docs/ARCHITECTURE.md` içinde ayrı başlıkla anlatılmalı.

### Senaryo 1: Karşılıklı ihtiyaç, döngüsüz çözüm
`payments`, bir tahsilatı gönderiye bağlamak için `ShipmentId` ve gönderi özetine ihtiyaç duyar. `shipments`, gönderi durumunu gösterirken ödeme durumuna ihtiyaç duyar. Çözüm: `payments_application` yalnızca `shipments_api`'ye, `shipments_application` yalnızca `payments_api`'ye bağımlanır. Sözleşme paketleri implementasyona bağımlı olmadığı için grafik döngüsüz kalır. `dep_graph` çıktısında bunu göster.

### Senaryo 2: Event üzerinden gevşek bağ
Teslimat tamamlandığında ilgili tahsilatın kapanması gerekir. `delivery_application` bir `DeliveryCompleted` domain event'i yayınlar, `payments_application` bunu dinler. İki application paketi birbirini hiç tanımaz, ikisi de yalnızca `core_ports` içindeki `DomainEventBus` portunu bilir.

### Senaryo 3: Tersine çevrilmiş bağımlılık
`sync` tüm feature'ların yazma işlemlerini taşır ama hiçbirini tanımaz. Feature'lar `sync_api`'ye bağımlanır, `sync` hiçbir feature'a bağımlanmaz. Bağımlılık oku, sezgisel beklentinin tersine akar.

### Senaryo 4: Aynı porta iki adapter
`RouteOptimizerPort`'un iki implementasyonu tek contract test kit'inden geçer. Uygulamalar farklı olanı bağlar. Çekirdek kodda tek satır değişmez.

### Senaryo 5: Farklı composition root'lar
Üç uygulama aynı `_application` paketlerini alır, farklı adapter setleriyle birleştirir:

| Port | app_courier | app_dispatcher | app_harness |
|---|---|---|---|
| `RouteOptimizerPort` | LocalHeuristicOptimizer | RemoteSolverOptimizer | FakeRouteOptimizer |
| `CredentialGateway` | DeviceBoundCredentialGateway | SsoCredentialGateway | FakeCredentialGateway |
| `OutboxStore` | DriftOutboxStore | InMemoryOutboxStore | InMemoryOutboxStore |
| `ProofStorePort` | LocalEncryptedProofStore | RemoteProofStore | FakeProofStore |
| `PaymentsGateway` | RestPaymentsGateway | RestPaymentsGateway | FakePaymentsGateway |

### Senaryo 6: İzin kontrolü sözleşme üzerinden
`shipments_presentation_dispatcher`, toplu atama butonunu göstermeden önce `identity_api`'deki `PermissionChecker`'ı sorar. Presentation, identity'nin implementasyonunu hiç tanımaz.

### Senaryo 7: Aynı feature, iki farklı UI
`shipments` feature'ının iki presentation paketi vardır. Bu, driving adapter'ın değiştirilebilirliğinin somut kanıtıdır.

---

## 6. Tooling

Bunlar gerçekten çalışan Dart CLI paketleri olacak, taslak değil. Her birinin kendi testleri var.

### 6.1 tooling/arch_check

Bağımlılık anayasasını doğrular. Kuralları `tooling/arch_check/rules.yaml` içinden okur, kod içine gömmez.

Yaptığı kontroller:
1. **Edge doğrulama**: Her paketin pubspec bağımlılıkları izin tablosuna uyuyor mu
2. **Deep import taraması**: Başka paketin `src/` klasörüne import var mı
3. **Yasaklı import**: `_api` ve `_application` paketlerinde `package:flutter/`, `package:dio/`, `package:drift/` var mı
4. **Döngü tespiti**: Grafikte cycle var mı
5. **Barrel disiplini**: Her paketin `lib/<paket_adı>.dart` barrel dosyası var mı ve `lib/` kökünde başka dosya var mı
6. **Yasaklı API kullanımı**: `DateTime.now()`, `Random()` doğrudan çağrısı var mı
7. **İsimlendirme**: Paket adı klasör adıyla uyuşuyor mu, `_api` paketinde implementasyon sınıfı var mı

Çıktı: okunabilir rapor artı `--format=json`. İhlalde exit code 1. Her ihlal mesajı hangi kuralı ihlal ettiğini ve nasıl düzeltileceğini yazar.

Kendi testleri: `test/fixtures/` altında kasten bozuk mini workspace'ler kur, her kuralın yakalandığını doğrula.

### 6.2 tooling/test_runner

Test koşumunu yöneten CLI.

Yetenekleri:
1. **Affected hesabı**: `--affected --base=origin/main`. Git diff'ten değişen paketleri bulur, bağımlılık grafiğinde dependent'ları yürür, koşulacak paket listesini üretir.
2. **Koşucu seçimi**: Paketin pubspec'inde `flutter` bağımlılığı yoksa `dart test`, varsa `flutter test`. Saf Dart paketleri için `-j` değerini çekirdek sayısına ayarlar.
3. **Bundling**: Bir paketin tüm `*_test.dart` dosyalarını import edip `main()`'lerini çağıran tek geçici entrypoint üretir. `--bundle` bayrağıyla açılır.
4. **Hash-skip**: Paket kaynakları artı transitif iç bağımlılıkların kaynakları artı `pubspec.lock` üzerinden sha256 hesaplar. `.cache/test_hashes.json` içinde bu hash için başarılı koşu varsa paketi atlar.
5. **Bucket'lama**: `--bucket i --total n` ile paketleri geçmiş süre verisine (`timings.json`) göre dengeli dağıtır.
6. **Raporlama**: JUnit XML çıktısı, koşulan paket sayısı, atlanan paket sayısı, toplam süre.

### 6.3 tooling/scaffold

Yeni feature iskeletini üretir:

```
dart run tooling/scaffold/bin/scaffold.dart new-feature --name billing --split full
dart run tooling/scaffold/bin/scaffold.dart new-feature --name faq --split reduced
```

Ürettikleri: tüm paket klasörleri, doğru bağımlılıklara sahip pubspec'ler, barrel dosyaları, `src/` iskeleti, boş test klasörleri, kök `pubspec.yaml` workspace listesine kayıt.

### 6.4 tooling/dep_graph

Bağımlılık grafiğini Mermaid ve Graphviz DOT formatında üretir, `docs/dependency-graph.md` dosyasına yazar. Paket tiplerini renk kodlar. Döngü varsa ayrıca raporlar.

---

## 7. Test stratejisi

Hedef, 100 bin test yazmak değil, 100 bin testi taşıyabilecek makineyi kurmak ve her mekanizmayı temsili örneklerle göstermek.

### 7.1 Test dağılımı hedefi

- Saf Dart unit test (`_api` ve `_application`): toplamın yüzde 80'i
- Bloc ve widget testi (`_presentation`): yüzde 15
- Golden test (`design_system` ve seçili ekranlar): yüzde 4
- Integration: yüzde 1

### 7.2 Contract test kit

Her `<feature>_testing` paketi, port'ları için ortak davranış suite'i sunar:

```dart
void runShipmentGatewayContract(ShipmentGateway Function() factory) { ... }
```

Aynı suite hem fake'e hem gerçek adapter'a koşulur. Fake ile gerçeğin davranışça ayrışmasını yapısal olarak engeller. En az `ShipmentGateway`, `RouteOptimizerPort`, `PaymentsGateway`, `OutboxStore` için kit yaz.

### 7.3 Fake'ler ve builder'lar

Mock kütüphanesi yerine davranış taşıyan fake'ler kullan. `core_testing` içinde `FakeClock`, `FakeIdGenerator`, `InMemoryKeyValueStore`, `RecordingEventBus`, `RecordingAnalyticsSink`. Her `<feature>_testing` içinde o feature'ın port fake'leri ve akıcı test data builder'ları.

### 7.4 Hermetiklik

- Gerçek saat kullanan test yok
- Gerçek ağ kullanan test yok, `platform/http_dio` içinde `FakeHttpTransport` üzerinden çalışılır
- Global state paylaşan test yok
- `dart_test.yaml` içinde varsayılan `retry: 0`, retry yalnızca `flaky` etiketli karantina suite'ine tanınır

### 7.5 Etiketleme ve preset'ler

`dart_test.yaml` içinde `unit`, `widget`, `golden`, `integration` etiketleri ve `pr` preset'i (golden ile integration hariç) tanımla.

### 7.6 docs/TESTING.md

Şunları içermeli: test piramidi ve gerekçesi, contract kit kullanımı, fake yazma kuralları, hermetiklik kuralları, flake yönetimi, ve "bu yapıda test sayısı 100 bine nasıl ulaşır" başlığı altında paket bazlı projeksiyon tablosu.

---

## 8. CI/CD

Dosyalar gerçek ve tutarlı olacak, sözde kod olmayacak.

### 8.1 .github/workflows/pr.yml
Checkout `fetch-depth: 0`, pinlenmiş Flutter sürümü, cache'li bootstrap, build_runner cache restore, sonra sırasıyla: format kontrolü, `melos run gen:check` (bayat generated dosya kontrolü), `dart analyze --fatal-infos`, `arch_check`, affected testler (`pr` preset, coverage kapalı), UI paketleri değiştiyse golden diff. PR yorumu olarak etkilenen paket listesi ve koşan test sayısı.

`gen:check` adımı kırıldığında hata mesajı geliştiriciye hangi komutu çalıştıracağını açıkça söylemeli.

### 8.2 .github/workflows/main.yml
Merge queue tetikli. 10 bucket'lı matrix ile tam suite. Timing JSON'unu artifact olarak sakla.

### 8.3 .github/workflows/nightly.yml
Tam suite artı tüm golden'lar artı integration testler artı coverage merge artı bağımlılık güncelleme kontrolü artı `melos run gen:all` ile tam yeniden üretim doğrulaması. Sonuncusu artımlı cache'in gizlediği bozulmaları yakalar.

### 8.4 .github/workflows/release.yml
Tag tetikli. Changelog üretimi, artifact build, sembol yükleme adımları.

### 8.5 codemagic.yaml
App bazlı koşullu tetikleme (`when: changeset`), flavor bazlı build, `--dart-define-from-file`, `--obfuscate --split-debug-info`.

### 8.6 fastlane/Fastfile
`beta`, `internal`, `promote_staged` lane'leri.

### 8.7 lefthook.yml
pre-commit: format ve değişen paketlerde analyze. pre-push: `melos run gen:check`, `arch_check` ve affected testler. Codegen kontrolünü pre-push'ta tutmanın nedeni, pre-commit'te çalıştırmanın her commit'i yavaşlatması.

---

## 9. Kod konvansiyonları

- Port'lar `abstract interface class` olarak tanımlanır
- Failure ve durum tipleri `sealed class` olur
- `Result<S, F>` tipi `core_kernel` içinde tanımlanır, `fold`, `map`, `flatMap` yardımcılarıyla
- Value object'ler private constructor artı doğrulama yapan factory ile kurulur, geçersiz durumda `Result` döner
- Entity'ler immutable, davranış taşır, `copyWith` ile evrilir
- Dosya adları snake_case, tek dosyada tek public tip
- Her paketin kısa bir `README.md`'si olur: paketin rolü, bağımlanabileceği paketler, içinde ne yaşamaz
- Kod üretimi kullanılır ve bir sonraki bölümde tanımlanan stratejiye uyulur

---

## 10. Kod üretimi stratejisi

Bu repo gerçek bir üretim projesi gibi kurulur, dolayısıyla build_runner ekosistemi tam olarak kullanılır. Ancak monorepo'da codegen kontrolsüz bırakılırsa hem derleme süresini hem test hızını yer bitirir. Aşağıdaki strateji zorunludur.

### 10.1 Kullanılacak araçlar ve yerleri

| Araç | Nerede kullanılır | Ne üretir |
|---|---|---|
| `freezed` | `<feature>_api` (entity, value object, sealed durum ve failure tipleri) | immutable sınıflar, `copyWith`, union tipleri |
| `json_serializable` | `<feature>_infrastructure` ve `platform/*` (yalnızca DTO'lar) | JSON dönüşümü |
| `drift_dev` | `platform/storage_drift` ve kalıcılık gerektiren `_infrastructure` paketleri | tablo sınıfları, DAO'lar, migration iskeleti |
| `injectable_generator` | yalnızca `apps/*` | DI kayıt kodu |
| `go_router_builder` | `<feature>_presentation*` | tip güvenli route tanımları |
| `flutter gen-l10n` | `apps/*` ve `design_system` | lokalizasyon sınıfları |
| `build_runner` | hepsinin koşucusu | - |

### 10.2 Değişmez codegen kuralları

1. **`core_kernel` içinde kod üretimi kullanılmaz.** Grafiğin en iç halkası olduğu için burada regen maliyeti tüm repoya yayılır. `Result`, `Failure` tabanı ve `ValueObject` elle yazılır.
2. **DTO'lar asla `_api` içinde tanımlanmaz.** `json_serializable` yalnızca `_infrastructure` ve `platform/*` paketlerinde çalışır. Bu ayrım korunmazsa serileştirme kaygısı domain'e sızar.
3. **`freezed` domain doğrulamasının yerini almaz.** Value object'lerin geçerlilik kontrolü elle yazılmış factory içinde kalır, `freezed` yalnızca veri taşıma iskeletini üretir.
4. **`injectable` yalnızca app katmanındadır.** Paketlerin içinde annotation tabanlı DI yoktur, bağımlılıklar constructor'dan geçer.
5. **Üretilmiş dosyalar repoya commit edilir.** `.gitignore` içine alınmaz.
6. **Üretilmiş dosyalar elle düzenlenmez.** Bir çıktı yanlışsa kaynak veya `build.yaml` düzeltilir.

### 10.3 Generated dosyaların commit edilme gerekçesi

Bu tercih bilinçlidir ve `docs/ARCHITECTURE.md` içinde açıklanmalıdır. Üç nedeni var.

Birincisi CI süresi: generated dosyalar repoda değilse her CI koşusunun başında tüm workspace için build_runner çalıştırmak gerekir, bu da PR pipeline'ına dakikalar ekler. Repoda olduklarında CI yalnızca tazelik doğrulaması yapar.

İkincisi review edilebilirlik: bir kaynak değişikliğinin ürettiği çıktı farkı PR diff'inde görünür. `freezed` union'ına eklenen bir case'in nereleri etkilediği gözle takip edilebilir.

Üçüncüsü ve en önemlisi affected hesabının doğruluğu: test seçimi git diff'e dayanıyor. Generated dosyalar repoda değilse, çalışma alanında sonradan üretilen dosyalar diff'te görünmez ve etkilenen paket hesabı yanlış çıkar.

Bedeli, diff gürültüsüdür. Bunu `.gitattributes` içinde `*.g.dart linguist-generated=true` ve `*.freezed.dart linguist-generated=true` satırlarıyla azalt.

### 10.4 Monorepo'da build_runner koşumu

Tüm workspace'te toptan codegen çalıştırmak kabul edilemez. Melos script'leri şöyle tanımlanır:

- `melos run gen`: yalnızca değişen paketlerde ve onların dependent'larında codegen çalıştırır (`--diff` ve `--include-dependents` filtreleriyle), her pakette `dart run build_runner build --delete-conflicting-outputs`
- `melos run gen:all`: tüm workspace, yalnızca nightly ve büyük refactor sonrası
- `melos run gen:check`: `gen` çalıştırıp `git diff --exit-code` ile bayatlık kontrolü, CI bunu kullanır
- `melos run gen:watch`: geliştiricinin üzerinde çalıştığı tek paket için watch modu

Her paketin kendi `build.yaml` dosyası olur ve **yalnızca ihtiyaç duyduğu builder'ları açar**. Varsayılan davranışta build_runner her pakette tüm builder'ları tarar, bu 74 pakette ciddi israftır. Örneğin `_api` paketlerinde yalnızca `freezed`, `_infrastructure` paketlerinde `freezed` ve `json_serializable` etkin olur, diğerleri `enabled: false` ile kapatılır. Ayrıca builder'ların çalışacağı glob'ları daralt (`generate_for` ile yalnızca ilgili klasörler).

### 10.5 CI ve cache

`pr.yml` içine `melos run gen:check` adımı eklenir ve analyze'dan önce koşar. Bayat generated dosya bulunursa pipeline kırılır ve geliştiriciye ne çalıştıracağı söylenir.

`.dart_tool/build` klasörü build_runner'ın artımlı cache'idir ve CI'da paket bazlı cache key ile saklanır. Bu cache olmadan `gen:check` adımı her koşuda sıfırdan üretim yapar.

### 10.6 arch_check ve test_runner uyarlamaları

`arch_check` şunları yapacak şekilde güncellenir:

- Üretilmiş dosyalar (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`) yasaklı API taramasından muaf tutulur, çünkü üretilen kodda `DateTime` veya benzeri kullanım geliştiricinin tercihi değildir
- Import kuralları generated dosyalarda da geçerlidir, çünkü bir paketin generated kodu izinsiz bir pakete bağımlanıyorsa bu gerçek bir mimari ihlaldir
- Yeni kural: `_api` paketlerinde `json_serializable` builder'ının etkin olmadığı doğrulanır (kural 10.2.2'nin makine kontrolü)
- Yeni kural: `core_kernel` içinde hiçbir generated dosya bulunmadığı doğrulanır

`test_runner` içinde hash hesabı generated dosyaları da kapsar. Bu doğaldır, çünkü generated dosyalar repoda olduğu için zaten paket kaynağının parçasıdır.

### 10.7 Codegen'in test hızına etkisi

`docs/TESTING.md` içinde şu not yer almalı: `freezed` ile üretilen sınıflar derleme süresini artırır ve bu, saf Dart test suite'lerinin başlangıç maliyetine yansır. Sıcak yolda olan ve çok sık test edilen paketlerde (özellikle `_api`) union tiplerini gereksiz yere büyütmekten kaçınılmalı. Ölçüm alışkanlığı kur: `test_runner` timing verisi bir paketin derleme süresi anormal büyüdüğünde bunu görünür kılar.

---

## 11. Repo yönetimi ve commit disiplini

Bu repo bir referans niteliğinde olacağı için git geçmişi de öğretici olmalı. Kod kadar geçmiş de düzenli tutulur.

### 11.1 Deponun açılması

Faz 0'ın ilk işi budur. `gh` CLI kurulu ve yetkili varsayılır, değilse kullanıcıya `gh auth login` çalıştırmasını söyle ve bekle.

```bash
mkdir flutter-hexagonal-monorepo && cd flutter-hexagonal-monorepo
git init -b main
gh repo create flutter-hexagonal-monorepo \
  --public \
  --source=. \
  --description "Hexagonal architecture (ports and adapters) in a large-scale Flutter monorepo: 74 packages, three apps, enforced dependency rules, and a test suite built to scale" \
  --remote=origin
```

Depo oluşturulduktan sonra konuları ekle. Keşfedilebilirlikte depo adı kadar topic'ler de belirleyicidir:

```bash
gh repo edit --add-topic flutter,dart,monorepo,hexagonal-architecture,ports-and-adapters,melos,clean-architecture,software-architecture,dependency-inversion,testing
```

İlk commit'ten önce şu dosyalar hazır olmalı: `README.md`, `LICENSE` (MIT), `.gitignore`, `.gitattributes`, `CLAUDE.md`.

### 11.2 .gitignore ve .gitattributes

`.gitignore` içinde **üretilmiş Dart dosyaları bulunmaz**. Bölüm 10.3'te gerekçesi anlatıldığı gibi `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart` repoya girer. Ignore edilecekler: `.dart_tool/`, `build/`, `.flutter-plugins*`, `*.iml`, `.idea/`, platform klasörlerinin türetilmiş çıktıları, `coverage/`, `.cache/`, `**/failures/` (golden test hata çıktıları).

`.gitattributes` içinde üretilmiş dosyalar işaretlenir:

```
*.g.dart linguist-generated=true
*.freezed.dart linguist-generated=true
*.gr.dart linguist-generated=true
*.config.dart linguist-generated=true
```

### 11.3 Dal (branch) stratejisi

- `main` korumalıdır, doğrudan push yapılmaz
- Her faz kendi dalında çalışılır: `phase/00-foundation`, `phase/01-core`, `phase/02-platform`, `phase/03-tooling`, `phase/04-reference-features`, `phase/05-cross-cutting`, `phase/06-light-features`, `phase/07-composition-roots`, `phase/08-ci-and-docs`
- Faz bitince PR açılır ve merge edilir
- Faz içinde ara işler için alt dal açma, tek dalda küçük commit'lerle ilerle

Faz 0'ın sonunda dal korumasını kur:

```bash
gh api -X PUT repos/:owner/flutter-hexagonal-monorepo/branches/main/protection \
  -f "required_status_checks[strict]=true" \
  -f "enforce_admins=false" \
  -f "required_pull_request_reviews[required_approving_review_count]=0" \
  -f "restrictions=null"
```

Koruma kuralı CI zorunluluğunu içerir. CI dosyaları Faz 8'de yazıldığı için status check zorunluluğunu o fazda etkinleştir.

### 11.4 Commit disiplini

**Sıklık:** Her anlamlı iş biriminde commit at. Faz sonunda tek dev commit atmak yasaktır. Pratik ölçü: bir paket tamamlandığında, bir kural `arch_check`'e eklendiğinde, bir contract kit yazıldığında ayrı commit. Bir fazın 15 ile 40 arası commit üretmesi normaldir.

**Format:** Conventional Commits. Kapsam olarak paket veya alan adı kullanılır.

```
<tip>(<kapsam>): <özet>

<gövde: neden bu değişiklik yapıldı, hangi mimari kararı yansıtıyor>
```

Tipler: `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`, `perf`.

Örnekler:

```
feat(shipments_api): add shipment status machine with transition rules

Transition validation lives in the Shipment entity rather than in a use
case, so that invalid transitions are impossible to construct regardless
of which adapter drives the change.
```

```
feat(tooling/arch_check): enforce json_serializable ban in api packages

Rule 10.2.2 was previously a written convention only. This makes it a
machine-checked constraint so DTO concerns cannot leak into the domain.
```

```
test(routing_testing): add RouteOptimizerPort contract suite

Both LocalHeuristicOptimizer and RemoteSolverOptimizer now run against
the same behavioral suite, preventing fake and real implementations from
drifting apart.
```

Gövde alanı bu repoda özellikle önemlidir. Referans amaçlı bir depo olduğu için "neden" bilgisi, kodun kendisi kadar değerlidir. Mimari bir karar veren her commit'in gövdesi doldurulur.

**Commit öncesi kontrol:** Hiçbir commit şu üç adım temiz geçmeden atılmaz:

```bash
melos run gen
dart analyze
dart run tooling/arch_check/bin/arch_check.dart
```

İlgili paketlerin testleri de geçmelidir. `arch_check` henüz yazılmadığı Faz 0 ile Faz 2 arasında kuralları elle doğrula ve commit gövdesinde hangi kuralı doğruladığını yaz.

**Yapılmayacaklar:** `--force` push yok, `main` üzerine rebase ile geçmiş yeniden yazma yok, üretilmiş dosyaları ayrı commit'e ayırma yok (kaynak ve çıktı aynı commit'te gider), sırf commit atmış olmak için anlamsız commit yok.

### 11.5 Faz sonu akışı

Her faz bittiğinde sırasıyla:

```bash
git push -u origin phase/04-reference-features

gh pr create \
  --title "Phase 4: reference features (identity, shipments)" \
  --body-file .github/phase-summary.md

gh pr merge --squash=false --merge
git checkout main && git pull

git tag -a phase-04 -m "Phase 4 complete: identity and shipments reference features"
git push origin phase-04
```

Merge sırasında squash kullanma. Faz içindeki commit geçmişi bu repoda öğretici bir değer taşıyor, korunmalı.

PR açıklaması şunları içerir: fazın kapsamı, eklenen paket sayısı ve listesi, mimarinin hangi kuralının bu fazda görünür hale geldiği, `arch_check` çıktısı, test sayısı, bilinen eksikler.

**Etiketler (tag):** Her fazın sonunda `phase-00` ile `phase-08` arası etiket atılır. Bu, referans deposu okuyan birinin mimarinin herhangi bir kuruluş aşamasına geri dönebilmesini sağlar. `README.md` içinde bu etiketlerin listesi ve her birinin ne içerdiği yer alır.

### 11.6 README.md

Kök `README.md` deponun vitrinidir ve şunları içerir: projenin ne olduğu ve neyi göstermek için var olduğu, mimari özet ve bağımlılık grafiği görseli, paket taksonomisi tablosu, hızlı başlangıç komutları, faz etiketleri listesi, `docs/` altındaki dokümanlara bağlantılar, dizin yapısı. İngilizce yazılır.

İlk paragrafta iki ismin ilişkisi net kurulur: depo hexagonal mimarinin büyük ölçekli bir Flutter monorepo'sundaki referans uygulamasıdır, Peyk ise bu mimarinin üzerinde gösterildiği örnek kurye ve sevkiyat ürünüdür. Okuyucu ilk cümlede neyi öğreneceğini, ikinci cümlede neye bakacağını bilmelidir.

### 11.7 CODEOWNERS ve şablonlar

`.github/CODEOWNERS`, `.github/pull_request_template.md` ve `.github/ISSUE_TEMPLATE/` altındaki şablonlar Faz 8'de eklenir. CODEOWNERS dosyası paket dizini bazlı yazılır ve büyük ekipte sahiplik dağılımının nasıl kurulacağını örnekler.

---

## 12. Faz planı

Fazları sırayla uygula. Her fazın sonunda kabul kriterini doğrula ve commit at. Bir fazı bitirmeden sonrakine geçme.

### Faz 0: Temel ve depo kurulumu
İlk iş depoyu açmaktır: bölüm 11.1'deki `gh` komutlarıyla `flutter-hexagonal-monorepo` deposunu oluştur, `main` dalını başlat, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes` dosyalarını yaz ve ilk commit'i at.

Ardından kök `pubspec.yaml` (workspace üyeleri ve melos konfigürasyonu), `analysis_options.yaml`, `dart_test.yaml`, `lefthook.yml`, `CLAUDE.md`, `docs/DEPENDENCY_RULES.md`.

Melos script'leri bu fazda tanımlanır: `gen`, `gen:all`, `gen:check`, `gen:watch`, `analyze`, `format`, `arch:check`, `test:affected`.

`analysis_options.yaml` içinde üretilmiş dosyalar için lint gevşetmesi tanımlanır ama analiz dışı bırakılmaz. Üretilmiş kodun derlenme hatalarını görmeye devam etmek gerekir.

`CLAUDE.md` içeriği kritik: mimari anayasa, paket tipleri tablosu, yasaklar listesi, codegen kuralları, commit disiplini, yeni paket ekleme prosedürü, sık yapılan hatalar. Sonraki oturumlar bu dosyayı okuyarak kuralları devralacak.

**Kabul:** Depo GitHub'da açık, `main` korumalı, kök yapı kurulu, `dart pub get` çalışıyor, melos script'leri tanımlı, `phase-00` etiketi atılmış.

### Faz 1: Core paketleri
`core_kernel`, `core_ports`, `core_navigation`, `core_testing`.

`core_kernel` acımasızca minimal olmalı: `Result`, `Failure` tabanı, `ValueObject`, `Entity`, `UseCase` imzası, `DomainEvent` tabanı. Bundan fazlası girmez.

`core_ports`: `Clock`, `IdGenerator`, `RandomSource`, `Logger`, `NetworkStatus`, `KeyValueStore`, `SecureStore`, `AnalyticsSink`, `FeatureFlagReader`, `DomainEventBus`, `PermissionRequester`.

`core_kernel` içinde kod üretimi kullanılmaz, her şey elle yazılır. `core_ports` ve `core_navigation` da elle yazılabilecek kadar dardır, gerekmedikçe builder açma.

**Kabul:** Dört paket derleniyor, `core_kernel` testleri geçiyor, `core_testing` fake'leri hazır, `core_kernel` içinde hiçbir generated dosya yok.

### Faz 2: Platform paketleri
Sekiz platform paketi. Her biri `core_ports` içindeki bir portu implemente eder. `http_dio` içinde `FakeHttpTransport` de bulunur.

`storage_drift` bu fazda drift tabloları, DAO'ları ve migration iskeletiyle kurulur. Migration testleri yaz: şema sürümleri arası geçişin veri kaybetmediğini doğrula.

Her platform paketine `build.yaml` ekle ve yalnızca ihtiyaç duyduğu builder'ları etkinleştir.

**Kabul:** Her platform paketi yalnızca `core_*` bağımlısı, `melos run gen` temiz koşuyor, drift migration testleri geçiyor.

### Faz 3: arch_check ve scaffold
İki tooling paketini yaz ve mevcut yapıya koştur. Bundan sonraki her fazın sonunda `arch_check` koşulacak.

`arch_check` bölüm 10.6'daki codegen kurallarını da içerecek. `scaffold` ürettiği her pakete doğru `build.yaml` dosyasını da koyacak.

**Kabul:** `arch_check` mevcut paketlerde sıfır ihlal raporluyor, fixture testleri geçiyor, `scaffold` yeni feature üretebiliyor ve ürettiği paketler `melos run gen` sonrası derleniyor.

### Faz 4: Referans feature'lar
`identity` ve `shipments`. Bunlar diğer feature'ların örnek alacağı referanslardır, en yüksek özenle yaz. `shipments` durum makinesi ve testleri burada tamamlanır. `shipments_testing` contract kit'i burada kurulur.

Codegen deseni de burada oturur: `_api` içinde entity ve sealed durum tipleri `freezed` ile, `_infrastructure` içinde DTO'lar `json_serializable` ile, aralarındaki mapper'lar elle. `shipments` durum makinesinin `freezed` union'ı üzerinden nasıl ifade edildiğini ve doğrulama mantığının neden hâlâ elle yazıldığını `docs/ARCHITECTURE.md` içinde örnekle anlat.

**Kabul:** `arch_check` temiz, `melos run gen:check` temiz, shipments durum makinesi testleri geçiyor, contract kit hem fake hem REST adapter'da koşuyor.

### Faz 5: Kesişen senaryolar
`routing`, `delivery`, `payments`, `sync`. Bölüm 5'teki yedi senaryonun tamamı bu fazda kodda görünür hale gelir.

**Kabul:** Grafikte döngü yok, event akışı testlerle doğrulanmış, idempotency testi geçiyor, `RouteOptimizerPort`'un iki implementasyonu da aynı contract kit'ten geçiyor.

### Faz 6: Hafif feature'lar
Yedi feature, üçer paket. Domain yüzeyleri dar ama kurallar aynı.

**Kabul:** `arch_check` temiz, paket sayısı hedefe ulaştı.

### Faz 7: Design system ve composition root'lar
`design_tokens`, `design_system`, sonra üç uygulama. Her app'in DI modülleri, route birleştirme, flavor yapılandırması. Bölüm 5.5'teki adapter tablosu birebir uygulanır.

DI kaydı `injectable` ile üretilir ama yalnızca app paketlerinde. Üç app'in üç farklı `injectable` konfigürasyonu, aynı `_application` paketlerinin farklı adapter setleriyle nasıl bağlandığını somut olarak gösterir. `go_router_builder` ile üretilen tip güvenli route'lar feature presentation paketlerinden export edilir, app bunları toplar.

**Kabul:** Üç app da derleniyor, `app_harness` tüm feature'ları fake'lerle ayağa kaldırıyor, container doğrulama testi (her port çözülebiliyor mu) geçiyor.

### Faz 8: Test runner, CI/CD ve dokümantasyon
`test_runner`, `dep_graph`, tüm CI dosyaları, `docs/ARCHITECTURE.md`, `docs/TESTING.md`, `docs/CI_CD.md`, üretilmiş bağımlılık grafiği.

`docs/ARCHITECTURE.md` en az şunları içermeli: hexagonal'ın bu repodaki karşılığı, paket tipleri ve gerekçeleri, bölüm 5'teki yedi senaryonun tek tek anlatımı, bir kullanıcı isteğinin paketler arasında izlediği yolun adım adım takibi, Mermaid diyagramları.

Bu fazda ayrıca `.github/CODEOWNERS`, PR ve issue şablonları eklenir ve `main` dalının koruma kuralına CI status check zorunluluğu tanımlanır.

**Kabul:** Tüm başarı kriterleri sağlanıyor, CI yeşil, `README.md` faz etiketlerini listeliyor, `phase-08` etiketi atılmış.

---

## 13. Yasaklar

Bunları yaparsan spec ihlal edilmiş olur:

1. `_api` veya `_application` paketine `flutter` bağımlılığı eklemek
2. Bir feature'ın `_application`, `_infrastructure` veya `_presentation` paketini başka bir feature'dan import etmek
3. `_application` ile `_infrastructure` arasında doğrudan bağ kurmak
4. İki feature arasındaki karşılıklı ihtiyacı ortak bir "shared" veya "common" paketi açarak çözmek
5. Paketlerin içinde `GetIt` veya global singleton kullanmak
6. `DateTime.now()`, `Random()` doğrudan çağırmak
7. Port sınırından exception fırlatmak
8. Başka paketin `src/` klasöründen import yapmak
9. Barrel dosyasından `src/` iç detaylarını export etmek
10. Üretilmiş dosyaları elle düzenlemek veya `.gitignore` içine almak
11. `core_kernel` içinde kod üretimi kullanmak
12. `_api` paketlerinde `json_serializable` çalıştırmak veya DTO tanımlamak
13. Paketlerin içinde annotation tabanlı DI (`injectable`) kullanmak
14. Bir pakette ihtiyaç duyulmayan builder'ları `build.yaml` içinde kapatmadan bırakmak
15. `core_kernel` paketine ihtiyaç duyulmayan tip eklemek
16. Tooling paketlerini test etmeden bırakmak
17. Bir fazın tüm işini tek commit'te toplamak
18. `main` dalına doğrudan push yapmak veya geçmişi yeniden yazmak
19. Üretilmiş dosyaları kaynaklarından ayrı bir commit'e koymak
20. Testleri ve `arch_check`'i geçmeyen bir değişikliği commit etmek

---

## 14. Çalışma şekli

- Her fazı ayrı oturumda çalış. Faz başında `CLAUDE.md` ve `docs/DEPENDENCY_RULES.md` dosyalarını oku, faz dalını aç.
- Her anlamlı iş biriminde commit at, faz sonunda push edip PR aç ve etiketle. Bölüm 11.4 ile 11.5'teki akışı izle.
- Her faz sonunda sırasıyla `melos run gen`, `dart analyze` ve `arch_check` koştur, üçü de temiz olmadan commit atma. Üretilmiş dosyaları commit'e dahil et.
- Bir dosyayı yazmadan önce hangi pakete ait olduğunu ve o paketin izinli bağımlılıklarını kontrol et. Bir sınıfın yeri konusunda tereddüt edersen `docs/DEPENDENCY_RULES.md` içindeki tabloya bak.
- Kısayol alma. Bir kuralı esnetmek zorunda kaldığını düşünüyorsan, esnetme yerine dur ve durumu raporla. Bu tür durumlar mimarinin en öğretici anlarıdır.
- Kod yorumlarını Türkçe değil İngilizce yaz. Dokümantasyon dosyalarını Türkçe yaz, teknik terimleri İngilizce bırak.