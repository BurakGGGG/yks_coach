# Zihin Rehberi — YKS Koç

Stitch'teki **YKS Hazırlık Asistanı** tasarımlarından geliştirilen Flutter uygulaması.

## Mevcut modüller

- Ana panel ve haftalık aktivite özeti
- Görev ekleme, tamamlama ve çalışma programı
- Çalışan Pomodoro sayacı, mola modları ve süre ayarı
- TYT/AYT deneme analizi ve deneme ekleme
- Düzenlenebilir öğrenci profili ve YKS hedefleri
- Bildirim tercihleri ve saat seçimi
- Yerel görev/günlük hatırlatmaları ve idempotent zamanlanmış FCM motivasyonu
- Gerçek kullanıcı bağlamını kullanan, günlük kota korumalı Gemini YKS Koçu
- Yeniden kimlik doğrulamalı, alt koleksiyonları da temizleyen hesap silme
- Kişisel veri eklemeyen release Crashlytics hata raporlama
- Açık/koyu tema ve mobil navigasyon
- Sayfa geçişleri, kart basma, sayaç, grafik ve ilerleme animasyonları
- Firestore profil/tercih, görev, deneme, odak ve sohbet kalıcılığı
- E-posta/şifre kaydı, e-posta doğrulama, şifre sıfırlama ve Google ile giriş

Uygulama `yks-coach-d8b65` Firebase projesine bağlıdır. Firestore verilerine
yalnızca e-postası doğrulanmış `password` veya `google.com` sağlayıcılı kullanıcı
erişebilir.

E-posta hesaplarında proje seviyesinde en az 10 karakter, büyük harf, küçük harf ve rakam zorunluluğu uygulanır. E-posta adresi keşfini zorlaştıran gelişmiş gizlilik ayarı ve 30 günlük anonim kullanıcı temizliği Firebase tarafında etkindir.

Yeni hesaplar demo verisi olmadan başlar: ilk girişte kısa bir onboarding ile
ad, sınıf, alan, hedef ve günlük hedefler alınır. Dashboard ve analizdeki tüm
istatistikler (çalışma süresi, tamamlanan görev, pomodoro, net ortalaması, zayıf
ders) yalnızca kullanıcının gerçek görev/odak/deneme kayıtlarından türetilir.

Uygulama katmanı domain'lere ayrılmıştır: `ProfileController`,
`ScheduleController`, `FocusController`, `ExamController`, `CoachController`
(her biri kendi repository'si üzerinden Firestore akışlarını dinler) ve saf
`analytics` hesaplama katmanı; hepsi `AppController` kökünde birleşir.

Firestore yapısı:

```text
users/{uid}
users/{uid}/tasks/{taskId}
users/{uid}/exams/{examId}
users/{uid}/focusSessions/{sessionId}
users/{uid}/coachMessages/{messageId}
users/{uid}/devices/{installationId}
users/{uid}/usage/{yyyy-MM-dd}
users/{uid}/notificationDeliveries/{deliveryId}
```

Koç ve hesap silme istekleri Firebase Auth, App Check enforcement ve tek
kullanımlık App Check tokenı korumalı callable fonksiyonlardan geçer. Android
Play Integrity/debug sağlayıcısı, web ise yalnız Firebase Hosting alanlarına
izin veren reCAPTCHA Enterprise sağlayıcısı kullanır. Node.js 22 fonksiyonu Vertex AI
üzerindeki `gemini-3.5-flash` modelini çağırır; profil, bugünkü görevler, son
denemeler ve son 14 günlük odak kayıtları sunucuda okunur. İstemci mesaj veya
kota belgesi yazamaz. Kullanıcı başına günlük sınır 20 mesajdır.

Firestore delete protection açıktır; kapalı beta süresince PITR kapalıdır.
Android ve web API anahtarları sırasıyla paket/SHA ve Hosting alanlarıyla
kısıtlanmıştır. Crashlytics yalnız release modunda çalışır; uygulama özel hata
mesajı, e-posta, UID, token veya sohbet metni eklemez.

Debug cihazda ilk çalıştırmada logcat'e yazılan App Check debug tokenı Firebase
Console > App Check > Android > Debug tokenlarını yönet bölümüne bir kez
eklenmelidir. Release derlemesi otomatik olarak Play Integrity kullanır.

## Release imzalama

Release yapılandırması debug anahtarı kullanmaz. Repo dışında oluşturulan upload
keystore için `android/key.properties.example` dosyasını
`android/key.properties` olarak kopyalayıp gerçek değerleri girin. Bu dosya ve
keystore `.gitignore` kapsamındadır. Release görevi, dosya yoksa güvenli biçimde
durur.

Gizlilik politikası ve Play Data Safety formu için gerçek veri akışı envanteri
[`docs/PRIVACY_DATA_INVENTORY.md`](docs/PRIVACY_DATA_INVENTORY.md) içindedir.

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Doğrulama

Tüm otomatik kontroller tek komutta toplanır:

```bash
make verify        # veya: ./tool/verify.sh
```

Bu komut biçim denetimi, `flutter analyze`, Flutter testleri, Cloud Functions
TypeScript lint/testi ve Firestore Rules emulator testlerini sırayla çalıştırır.

Görsel ve font varlıkları `pubspec.yaml` içindeki `assets` ve `google_fonts` yapılandırmalarıyla yönetilir.

## Şema sürümü

`users/{uid}` belgeleri `schemaVersion` alanı taşır (güncel: `1`). Belge
biçimi değiştiğinde [`lib/services/schema.dart`](lib/services/schema.dart)
içindeki `kCurrentSchemaVersion` artırılır ve `migrateUserData` içine geriye
uyumlu bir dönüştürme adımı eklenir; uygulamanın geri kalanı her zaman güncel
biçimi görür.
