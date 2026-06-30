# Zihin Rehberi — Gizlilik ve Play Data Safety Teknik Envanteri

Bu belge hukuki politika değildir. Canlı uygulama ve backend veri akışlarının,
gizlilik politikası ile Google Play Data Safety formuna aktarılacak teknik
envanteridir. Son beyan geliştirici tarafından doğrulanmalıdır.

## Toplanan ve işlenen veriler

| Veri | Amaç | Saklama/temizleme |
|---|---|---|
| E-posta, Firebase UID, giriş sağlayıcısı | Hesap oluşturma, giriş ve yetkilendirme | Hesap silme callable işlemi Auth kaydını siler |
| Ad, sınıf, alan, hedef üniversite/bölüm/sıralama | Kişiselleştirilmiş çalışma planı ve koç bağlamı | `users/{uid}` altında; hesap silmede recursive silinir |
| Görevler, denemeler, ders sonuçları, odak oturumları | Program, analiz ve gelişim metrikleri | Kullanıcı hesabında; hesap silmede recursive silinir |
| Koç mesajları | Gemini yanıtı ve konuşma geçmişi | En fazla 100 mesaj; kullanıcı temizleyebilir veya hesapla birlikte silinir |
| FCM tokenı, kurulum kimliği, saat dilimi, bildirim tercihleri | Cihaza bildirim teslimi ve yerel saat hesabı | Cihaz kaydı çıkışta/devre dışı bırakmada veya hesap silmede silinir |
| Bildirim teslimat kayıtları | Aynı motivasyon bildiriminin tekrarını önleme | Kullanıcı alt koleksiyonunda; hesap silmede silinir |
| Çökme stack trace'i, uygulama/işletim sistemi ve cihaz tanılama bilgileri, Crashlytics/Firebase kurulum kimlikleri | Release kararlılığını izleme | Firebase Crashlytics hizmet saklama politikasına tabi |

## Harici hizmetler

- Firebase Authentication: e-posta/şifre ve Google girişleri.
- Cloud Firestore: kullanıcı profili ve çalışma verileri.
- Cloud Functions ve Vertex AI: koç isteği, gerçek kullanıcı bağlamı ve model yanıtı.
- Firebase Cloud Messaging: bildirim tokenı ve teslimat.
- Firebase App Check / Play Integrity / reCAPTCHA Enterprise: uygulama ve istek doğrulaması.
- Firebase Crashlytics: release çökme ve fatal hata tanılaması.

## Uygulama tarafından eklenmeyen veriler

- Reklam kimliği, reklam veya davranışsal reklam profili yoktur.
- Hassas/ince konum, kişiler, fotoğraf/video, mikrofon, SMS, sağlık, finans ve ödeme verisi alınmaz.
- Crashlytics'e özel kullanıcı kimliği, e-posta, token, sohbet/görev metni veya ham exception mesajı eklenmez.
- Google Analytics SDK'sı ekli değildir.

## Google Play Data Safety taslak eşlemesi

Kesin seçimler Play Console'daki güncel sorulara göre kontrol edilmelidir:

- Kişisel bilgiler: e-posta ve kullanıcı adı — hesap yönetimi/uygulama işlevselliği, gerekli.
- Uygulama etkinliği veya kullanıcı tarafından oluşturulan içerik: görev, deneme, odak ve koç mesajları — uygulama işlevselliği ve kişiselleştirme, gerekli.
- Uygulama bilgileri ve performans: çökme günlükleri ve tanılama — analiz/uygulama kararlılığı, release modunda.
- Cihaz veya diğer kimlikler: Firebase/Crashlytics kurulum kimlikleri ve FCM tokenı — bildirim, güvenlik ve kararlılık.
- Veriler aktarım sırasında şifrelenir ve uygulama içinde hesap silme isteği sunulur.
- Google/Firebase'in hizmet sağlayıcı olarak işlediği verilerin “paylaşım” sınıflandırması, Play'in güncel hizmet sağlayıcı istisnasına göre geliştirici tarafından doğrulanmalıdır.

## Politika yayımlamadan önce gerekenler

- Geliştirici veya veri sorumlusunun yayımlanacak adı.
- Kullanıcıların erişebileceği destek/gizlilik e-posta adresi.
- Varsa şirket unvanı, adresi ve ülke mevzuatına göre zorunlu iletişim bilgileri.
- Politikanın yürürlük tarihi ve değişiklik bildirim yöntemi.
- Firebase Hosting üzerinde kalıcı gizlilik ve hesap silme URL'leri.
