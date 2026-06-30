# YKS Koç — Yayınlanabilir MVP Yol Haritası

## Özet

Hedef: Android öncelikli, Play kapalı betaya hazır, gerçek kullanıcı verileriyle çalışan güvenli MVP. Web’de giriş ve temel veri akışı korunacak; web push ve iOS kapsam dışında kalacak.

Uygulama sırası: proje güvenliği → gerçek veri modeli → çekirdek özellikler → bildirimler → Gemini koç → güvenlik/izleme → kapalı beta.

## Güncel Durum — 30 Haziran 2026

- Aşama 0–4 tamamlandı; Functions, Rules ve indeksler canlı Firebase projesine dağıtıldı.
- Aşama 5'te hesap silme, Crashlytics, API anahtarı kısıtları, delete protection, Android/web App Check sağlayıcıları ve callable enforcement tamamlandı.
- Firestore App Check enforcement, yeni web istemcisi deploy edilip iki platformda metrik doğrulaması yapılana kadar gözlem modunda tutuluyor.
- Gizlilik politikası için teknik veri envanteri hazır; yayın öncesi geliştirici/veri sorumlusu adı ve destek e-postası gerekiyor.
- Aşama 6 başladı: uygulama kimliği sabit, sürüm `1.0.0+2` ve release debug imzasından ayrıldı. Upload keystore, Play App Signing SHA değerleri ve mağaza varlıkları kullanıcı hesabında tamamlanacak.
- Kullanıcı onayı olmadan APK/AAB üretilmeyecek ve web uygulaması başlatılmayacak.

## Uygulama Aşamaları

### 0. Güvenli geliştirme temeli

- İçeriği boş olan `.git` yapısını düzelterek mevcut kaynakların başlangıç commit’ini oluştur.
- Firebase yapılandırmaları ve imza dosyaları için `.gitignore` kurallarını kesinleştir; hiçbir özel anahtar repoya girmez.
- `flutter analyze`, `flutter test`, Functions lint/test ve Firestore Rules testlerini tek doğrulama komutunda birleştir.
- Firestore verilerine `schemaVersion` ekle; eski belge biçimlerini okuyabilen geriye uyumlu dönüştürücüler oluştur.

Çıkış kriteri: temiz başlangıç commit’i, tekrarlanabilir doğrulama komutu ve veri kaybetmeden şema yükseltme altyapısı.

### 1. Örnek verileri kaldırma ve onboarding

- Yeni kullanıcıya 2023/2024 görev, deneme ve sohbet kayıtları yazmayı kaldır.
- İlk girişte ad, sınıf, alan, hedef üniversite/bölüm, sıralama ve günlük çalışma hedeflerini alan kısa onboarding göster.
- Hafta başlangıcını cihazın güncel tarihine göre pazartesi olarak hesapla.
- `users/{uid}` belgesine `onboardingCompleted`, `schemaVersion`, `locale`, `timeZone`, `createdAt`, `updatedAt` alanlarını ekle.
- Boş görev, deneme ve odak geçmişi için gerçek empty-state ekranları kullan.

Çıkış kriteri: yeni hesap hiçbir sahte başarı metriği görmeden onboarding’i tamamlayıp kendi verilerini oluşturmaya başlayabilir.

### 2. Gerçek çalışma ve analiz verileri

- Görev modelini metin saat yerine `scheduledDate`, `startMinutes`, `endMinutes`, durum ve oluşturulma zamanı ile yapılandır.
- Görev ekleme yanında düzenleme, silme ve hafta sonu desteği ekle.
- Pomodoro sayacını saniye azaltmak yerine gerçek `startedAt/endAt` üzerinden çalıştır; uygulama arka plana girip dönünce süre doğru kalır.
- Tamamlanan her odak çalışmasını `users/{uid}/focusSessions/{sessionId}` altında sakla.
- Denemelerde yalnız toplam net yerine ders bazında doğru, yanlış, boş ve net bilgisi al; neti `doğru - yanlış / 4` olarak hesapla.
- Dashboard’daki `4s`, `%85`, haftalık grafik ve çözülen soru değerlerini gerçek görev/odak/deneme kayıtlarından üret.
- Analizde zayıf ders, ortalama, gelişim grafiği ve son denemeleri gerçek veriden hesapla.
- Tek parça `AppState` sorumluluklarını profil, program, odak ve analiz controller/repository katmanlarına ayır; Android ve web değişikliklerini Firestore akışlarıyla senkronize et.

Yeni koleksiyonlar:

```text
users/{uid}
users/{uid}/tasks/{taskId}
users/{uid}/exams/{examId}
users/{uid}/focusSessions/{sessionId}
users/{uid}/coachMessages/{messageId}
users/{uid}/devices/{installationId}
users/{uid}/usage/{yyyy-MM-dd}
```

Çıkış kriteri: uygulamada görünen bütün istatistikler kullanıcı eylemlerinden türetilir ve iki cihaz arasında güncellenir.

### 3. Android bildirim sistemi

- `firebase_messaging`, `flutter_local_notifications` ve timezone desteği ekle.
- Android 13+ bildirim iznini onboarding sırasında değil, kullanıcı ilk hatırlatmayı etkinleştirdiğinde iste.
- Günlük özet ve görev başlangıç hatırlatmalarını cihazda zamanla; görev düzenleme/silmede eski alarmı iptal et.
- FCM tokenlarını kullanıcı ve kurulum kimliği altında sakla, token yenilenmesini takip et ve çıkışta cihaz kaydını kaldır.
- Functions v2 zamanlayıcısıyla motivasyon bildirimlerini günde en fazla bir kez gönder; aynı bildirimin tekrar gönderilmesini idempotency kaydıyla önle.
- Bildirime dokunulduğunda ilgili görev, analiz veya asistan ekranını aç.
- Web push ilk MVP’ye dahil edilmez. Android foreground/background/terminated durumları test edilir. [Firebase Flutter FCM rehberi](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [zamanlanmış Functions](https://firebase.google.com/docs/functions/schedule-functions)

Çıkış kriteri: görev ve günlük özet çevrimdışı zamanlanır; sunucu bildirimi doğru kullanıcıya gider ve uygulamada doğru hedefi açar.

### 4. Sunucu tarafında Gemini YKS Koçu

- TypeScript ve Node.js 22 ile Cloud Functions v2 altyapısı kur. [Desteklenen Functions runtime’ları](https://firebase.google.com/docs/functions/manage-functions)
- Vertex AI üzerinden yapılandırılabilir model adıyla `gemini-3.5-flash` kullan; API anahtarı istemciye veya repoya konmaz.
- `askCoach` callable arayüzü:

```text
Girdi:
  message: string, 1–2000 karakter
  conversationId: string

Çıktı:
  messageId: string
  answer: string
  remainingDailyQuota: int
  createdAt: timestamp
```

- Fonksiyon yalnız doğrulanmış Firebase Auth ve geçerli App Check tokenı kabul eder.
- Sunucu bağlamı kullanıcının profilinden, bugünkü görevlerinden, son 10 denemesinden ve son 14 günlük odak kayıtlarından oluşturur; istemcinin gönderdiği istatistiklere güvenmez.
- Kullanıcı başına günlük 20 mesaj kotasını Firestore transaction ile uygula.
- Cevabı yaklaşık 700 tokenla sınırla; Türkçe, YKS koçluğu odaklı ve ölçülü sistem talimatı kullan.
- Güvenlik filtreleri, timeout, model hatası ve kota dolumu için kullanıcıya anlaşılır hata kodları döndür.
- Kullanıcı ve asistan mesajlarını yalnız fonksiyon yazar; istemci doğrudan asistan cevabı oluşturmaz.
- Sohbet geçmişini en fazla 100 mesajla sınırla ve “Geçmişi temizle” işlemi ekle.
- Callable isteklerinde Auth ve App Check belirteçleri otomatik taşınır. [Firebase callable Functions](https://firebase.google.com/docs/functions/callable)

Çıkış kriteri: asistan gerçek kullanıcı verisini kullanır, günlük 20 mesaj sınırı aşılmaz ve model anahtarı/erişimi istemciden çıkarılmıştır.

### 5. Güvenlik, gizlilik ve dayanıklılık

- App Check’i Android’de Play Integrity, web’de reCAPTCHA sağlayıcısıyla kaydet; önce metrik modunda gözlemle, ardından Firestore ve Functions için enforcement aç. [Flutter App Check kurulumu](https://firebase.google.com/docs/app-check/flutter/default-providers)
- Firestore Rules’ı yeni koleksiyon ve alanlar için tip, uzunluk, UID ve doğrulanmış sağlayıcı kontrolleriyle genişlet.
- Rules Emulator testlerinde anonim, doğrulanmamış, başka UID, bozuk alan ve kota aşımı senaryolarını reddet.
- `deleteAccount` callable fonksiyonuyla tüm alt koleksiyonları, cihaz tokenlarını ve Auth hesabını geri döndürülemez biçimde sil.
- Kullanıcıya sohbet geçmişini temizleme ve hesap silme seçenekleri sun.
- Firebase Crashlytics ekle; loglarda mesaj içeriği, e-posta, token veya kişisel veri tutma.
- Firestore delete protection aç; kapalı beta boyunca PITR kapalı kalsın.
- Android ve web API anahtarlarını uygulama kimliği/SHA ve alan adlarıyla sınırla.
- Kapalı beta öncesinde `localhost` yetkili alanını kaldır.
- Gizlilik politikası ve hesap silme açıklamasını Firebase Hosting üzerinde yayımla.

Çıkış kriteri: kötü niyetli istemci doğrudan veri veya AI erişimi alamaz; kullanıcı hesabını ve verisini tamamen silebilir.

### 6. Play kapalı beta hazırlığı

- Android uygulama adını `Zihin Rehberi`, paket kimliğini mevcut `com.ykscoach.yks_coach` olarak sabitle.
- Debug imzasını release yapılandırmasından kaldır; repo dışında upload keystore ve ignored `key.properties` kullan.
- Play App Signing’i etkinleştir; upload ve Play SHA-1/SHA-256 değerlerini Firebase Auth ve App Check’e ekle.
- Sürümü `1.0.0+2` ile başlat; sonraki her yüklemede build numarasını artır.
- Uygulama ikonu, adaptive icon, splash, mağaza açıklaması, ekran görüntüleri, içerik derecelendirmesi ve Data Safety formunu hazırla.
- Crashlytics’siz çökme, auth başarısızlığı, Functions hata oranı, AI kota/maliyet ve FCM teslimatını beta boyunca izle.
- İlk beta grubunda onboarding → görev → odak → deneme → analiz → asistan → bildirim → hesap silme uçtan uca senaryosunu çalıştır.
- AAB üretimi ve Play yüklemesi yalnız kullanıcı ayrıca onayladığında yapılır; planın diğer aşamalarında APK/web başlatılmaz.

## Test ve Kabul Planı

- Unit: net hesaplama, haftalık metrikler, timer yaşam döngüsü, kota ve model dönüşümleri.
- Widget: onboarding, boş durumlar, görev/deneme CRUD, izin reddi, AI kota ve hata ekranları.
- Emulator: Auth, Firestore Rules, Functions ve veri silme akışları.
- Android cihaz/emülatör: Google/e-posta giriş, doğrulama, arka plan timer, yerel bildirim, FCM ve deep-link.
- Güvenlik: anonim/doğrulanmamış erişim `403`, başka UID erişimi reddi, App Check’siz callable reddi.
- Performans: ilk açılışta gereksiz koleksiyon taraması olmaması, listelerde sayfalama ve sınırlı Firestore dinleyicisi.
- Beta kabulü: analiz temiz, tüm otomatik testler geçer, P0/P1 hata yok, sahte metrik yok ve tüm kullanıcı verileri hesap silmede temizlenir.

## Sabit Varsayımlar

- İlk hedef Android Play kapalı beta; web temel giriş/veri için çalışır, web push ve iOS kapsam dışıdır.
- Yeni hesaplar temiz başlar; demo verisi oluşturulmaz.
- Google ve e-posta/şifre tek giriş sağlayıcılarıdır.
- AI, Cloud Functions üzerinden Vertex AI Gemini kullanır ve günlük kota 20 mesajdır.
- Bildirimler Android yerel zamanlama + FCM modelindedir.
- Varsayılan saat dilimi cihazdan alınır; bulunamazsa `Europe/Istanbul` kullanılır.
- Monetizasyon, abonelik, admin paneli ve veli/öğretmen rolleri bu MVP’nin dışında kalır.
