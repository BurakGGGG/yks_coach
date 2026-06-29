# Zihin Rehberi — YKS Koç

Stitch'teki **YKS Hazırlık Asistanı** tasarımlarından geliştirilen Flutter uygulaması.

## Mevcut modüller

- Ana panel ve haftalık aktivite özeti
- Görev ekleme, tamamlama ve çalışma programı
- Çalışan Pomodoro sayacı, mola modları ve süre ayarı
- TYT/AYT deneme analizi ve deneme ekleme
- Düzenlenebilir öğrenci profili ve YKS hedefleri
- Bildirim tercihleri ve saat seçimi
- Hızlı öneriler ile çalışan yerel YKS Asistanı demosu
- Açık/koyu tema ve mobil navigasyon
- Sayfa geçişleri, kart basma, sayaç, grafik ve ilerleme animasyonları
- Firebase anonim oturum, Firestore profil/tercih, görev, deneme ve sohbet kalıcılığı
- E-posta/şifre kaydı, e-posta doğrulama, şifre sıfırlama ve Google ile giriş

Uygulama `yks-coach-d8b65` Firebase projesine bağlıdır. İlk açılışta geçici anonim oturum oluşturulur ve kullanıcı giriş/kayıt ekranına yönlendirilir. Yeni e-posta veya Google hesabı bu geçici kullanıcıya bağlandığı için mevcut veriler ve UID korunur. Firestore verilerine yalnızca e-postası doğrulanmış `password` veya `google.com` sağlayıcılı kullanıcı erişebilir.

E-posta hesaplarında proje seviyesinde en az 10 karakter, büyük harf, küçük harf ve rakam zorunluluğu uygulanır. E-posta adresi keşfini zorlaştıran gelişmiş gizlilik ayarı ve 30 günlük anonim kullanıcı temizliği Firebase tarafında etkindir.

Firestore yapısı:

```text
users/{uid}
users/{uid}/tasks/{taskId}
users/{uid}/exams/{examId}
users/{uid}/coachMessages/{messageId}
```

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Doğrulama

```bash
flutter analyze
flutter test
flutter build web --release
```

Görsel ve font varlıkları `pubspec.yaml` içindeki `assets` ve `google_fonts` yapılandırmalarıyla yönetilir.
