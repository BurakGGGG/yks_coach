import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/app.dart';
import 'package:yks_coach/services/auth_service.dart';
import 'package:yks_coach/state/app_state.dart';
import 'package:yks_coach/state/auth_session.dart';

void main() {
  testWidgets('ana modüller arasında gezinir', (tester) async {
    _setMobileSurface(tester);
    final state = AppState();
    await tester.pumpWidget(YksCoachApp(state: state));
    expect(find.text('Günaydın, Ali.'), findsOneWidget);

    await tester.tap(find.text('Odak'));
    await tester.pumpAndSettle();
    expect(find.text('ÇALIŞMA KONUSU'), findsOneWidget);

    await tester.tap(find.text('Analiz'));
    await tester.pumpAndSettle();
    expect(find.text('Deneme Analizi'), findsOneWidget);

    await tester.tap(find.text('Program'));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2023'), findsOneWidget);
    state.dispose();
  });

  testWidgets('tema anahtarı koyu temayı açar', (tester) async {
    _setMobileSurface(tester);
    final state = AppState();
    await tester.pumpWidget(YksCoachApp(state: state));
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koyu tema'));
    await tester.pumpAndSettle();
    expect(state.themeMode, ThemeMode.dark);
    state.dispose();
  });

  testWidgets('pomodoro sayacı başlatılır ve sıfırlanır', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 1);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.text('Başla'));
    await tester.pump(const Duration(seconds: 1));
    expect(state.timerRunning, isTrue);
    expect(find.text('Duraklat'), findsOneWidget);
    await tester.tap(find.byTooltip('Sıfırla'));
    await tester.pump();
    expect(state.timerRunning, isFalse);
    expect(state.remainingSeconds, 25 * 60);
    state.dispose();
  });

  testWidgets('tamamlanan odak oturumu istatistiklere eklenir', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 1)..remainingSeconds = 1;
    final firstSessionCount = state.completedFocusSessions;
    final firstTotal = state.totalFocusMinutes;
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.text('Başla'));
    await tester.pump(const Duration(seconds: 1));
    expect(state.completedFocusSessions, firstSessionCount + 1);
    expect(state.totalFocusMinutes, firstTotal + state.focusMinutes);
    state.dispose();
  });

  testWidgets('özel odak süresi çalışma modunu korur', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 1)..setFocusMinutes(40);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('40:00'), findsOneWidget);
    expect(state.timerMode, 'focus');
    state.dispose();
  });

  testWidgets('programdaki görev odak ekranına aktarılır', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 3);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.byTooltip('Odak oturumu başlat').at(2));
    await tester.pumpAndSettle();
    expect(state.tabIndex, 1);
    expect(state.focusSubject, contains('Geometri'));
    expect(find.text('ÇALIŞMA KONUSU'), findsOneWidget);
    state.dispose();
  });

  testWidgets('yeni deneme analize eklenir', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 2);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.byTooltip('Deneme ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Haftalık TYT');
    await tester.enterText(find.byType(TextField).at(1), '81.25');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(state.exams.first.name, 'Haftalık TYT');
    expect(state.exams.first.net, 81.25);
    state.dispose();
  });

  testWidgets('çekmece yardımcı ekranları açar ve profil kaydedilir', (
    tester,
  ) async {
    _setMobileSurface(tester);
    final state = AppState();
    await tester.pumpWidget(YksCoachApp(state: state));

    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profilim'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Öğrenci bilgileri'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Ayşe Demir');
    final save = find.text('Değişiklikleri kaydet');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(state.userName, 'Ayşe Demir');
    state.dispose();
  });

  testWidgets('program hafta okları gerçek tarihi değiştirir', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 3);
    final firstWeek = state.weekStart;
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.byTooltip('Sonraki hafta'));
    await tester.pumpAndSettle();
    expect(state.weekStart, firstWeek.add(const Duration(days: 7)));
    await tester.tap(find.byTooltip('Önceki hafta'));
    await tester.pumpAndSettle();
    expect(state.weekStart, firstWeek);
    state.dispose();
  });

  testWidgets('program görevleri seçilen güne ekler', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 3);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.text('Pzt'));
    await tester.pumpAndSettle();
    expect(find.text('Bu gün için görev yok'), findsOneWidget);

    await tester.tap(find.text('Görev ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Fonksiyon tekrar',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Fonksiyon tekrar'), findsOneWidget);
    expect(state.selectedDayTasks.single.scheduledDate, state.selectedDate);
    state.dispose();
  });

  testWidgets('analiz türü içeriği ve metrikleri günceller', (tester) async {
    _setMobileSurface(tester);
    final state = AppState(initialTab: 2);
    await tester.pumpWidget(YksCoachApp(state: state));
    await tester.tap(find.text('AYT'));
    await tester.pumpAndSettle();
    expect(state.examType, 'AYT');
    expect(find.text('Ders Bazlı Analiz (AYT)'), findsOneWidget);
    expect(find.text('Kimya'), findsAtLeastNWidgets(1));
    state.dispose();
  });

  testWidgets('asistan hızlı soruya yanıt üretir', (tester) async {
    _setMobileSurface(tester);
    final state = AppState();
    await tester.pumpWidget(YksCoachApp(state: state));
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('YKS Asistanı'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Netlerimi yorumla'), findsOneWidget);
    await tester.ensureVisible(find.text('Netlerimi yorumla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netlerimi yorumla'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.textContaining('Son TYT ortalaman'), findsOneWidget);
    state.dispose();
  });

  testWidgets('giriş ve güvenli kayıt formu durumları çalışır', (tester) async {
    _setMobileSurface(tester);
    final session = AuthSession(
      auth: _FakeAuthGateway(),
      initialTab: 0,
      initialDark: false,
    )..stage = AuthStage.authentication;
    await tester.pumpWidget(YksCoachRoot(session: session));
    expect(find.text('Google ile devam et'), findsOneWidget);
    expect(find.text('Şifremi unuttum'), findsOneWidget);

    await tester.tap(find.text('Hesap oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Ad soyad'), findsOneWidget);
    expect(find.textContaining('En az 10 karakter'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-posta'),
      'gecersiz',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre').first,
      'zayif',
    );
    await tester.tap(find.text('Hesabımı oluştur'));
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi gir'), findsOneWidget);
    expect(
      find.text('Şifre güvenlik koşullarını karşılamıyor'),
      findsOneWidget,
    );
    session.dispose();
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _setMobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 884);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
