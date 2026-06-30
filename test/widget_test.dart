import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_coach/app.dart';
import 'package:yks_coach/data/memory_store.dart';
import 'package:yks_coach/models/study_task.dart';
import 'package:yks_coach/models/user_profile.dart';
import 'package:yks_coach/screens/onboarding_screen.dart';
import 'package:yks_coach/services/auth_service.dart';
import 'package:yks_coach/state/app_controller.dart';
import 'package:yks_coach/state/auth_session.dart';

AppController _buildApp({
  UserProfile? profile,
  List<StudyTask> tasks = const [],
  int initialTab = 0,
}) {
  final app = AppController(
    repositories: memoryRepositories(profile: profile, tasks: tasks),
    initialTab: initialTab,
  );
  addTearDown(app.dispose);
  return app;
}

UserProfile _onboarded({String name = 'Ada Yılmaz'}) => UserProfile(
  userName: name,
  grade: '12. Sınıf',
  targetRank: 5000,
  onboardingCompleted: true,
);

Future<void> _pumpApp(
  WidgetTester tester,
  AppController app, {
  String? screen,
}) async {
  _setMobileSurface(tester);
  await tester.pumpWidget(YksCoachApp(controller: app, initialScreen: screen));
  await tester.pump(); // deliver first stream snapshots
  await tester.pumpAndSettle(); // drain entrance animations / timers
}

void main() {
  testWidgets('ana modüller arasında gezinir', (tester) async {
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app);
    expect(find.text('Merhaba, Ada.'), findsOneWidget);

    await tester.tap(find.text('Odak'));
    await tester.pumpAndSettle();
    expect(find.text('ÇALIŞMA KONUSU'), findsOneWidget);

    await tester.tap(find.text('Analiz'));
    await tester.pumpAndSettle();
    expect(find.text('Deneme Analizi'), findsOneWidget);

    await tester.tap(find.text('Program'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sonraki hafta'), findsOneWidget);
  });

  testWidgets('sekme geçişi yönü izler ve ekran kaydırmasını korur', (
    tester,
  ) async {
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    final dashboardScroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(dashboardScroll, greaterThan(0));

    await tester.tap(find.text('Odak'));
    await tester.pump();
    final forwardSlide = tester.widget<FractionalTranslation>(
      find
          .descendant(
            of: find.byKey(const ValueKey('tab-1')),
            matching: find.byType(FractionalTranslation),
          )
          .first,
    );
    expect(forwardSlide.translation.dx, greaterThan(0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Panel'));
    await tester.pump();
    final backwardSlide = tester.widget<FractionalTranslation>(
      find
          .descendant(
            of: find.byKey(const ValueKey('tab-0')),
            matching: find.byType(FractionalTranslation),
          )
          .first,
    );
    expect(backwardSlide.translation.dx, lessThan(0));
    await tester.pumpAndSettle();

    final restoredScroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(restoredScroll, closeTo(dashboardScroll, .1));
  });

  testWidgets('azaltılmış hareket ayarında sekmeler anında değişir', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app);

    await tester.tap(find.text('Odak'));
    await tester.pump();

    expect(find.text('ÇALIŞMA KONUSU'), findsOneWidget);
    final slide = tester.widget<FractionalTranslation>(
      find
          .descendant(
            of: find.byKey(const ValueKey('tab-1')),
            matching: find.byType(FractionalTranslation),
          )
          .first,
    );
    expect(slide.translation, Offset.zero);
  });

  testWidgets('tema anahtarı koyu temayı açar', (tester) async {
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app);
    final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koyu tema'));
    await tester.pumpAndSettle();
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('pomodoro sayacı başlatılır ve sıfırlanır', (tester) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 1);
    app.focus.selectSubject('Matematik');
    await _pumpApp(tester, app);
    await tester.tap(find.text('Başla'));
    await tester.pump(const Duration(seconds: 1));
    expect(app.focus.running, isTrue);
    expect(find.text('Duraklat'), findsOneWidget);
    await tester.tap(find.byTooltip('Sıfırla'));
    await tester.pump();
    expect(app.focus.running, isFalse);
    expect(app.focus.remainingSeconds, 25 * 60);
  });

  testWidgets('özel odak süresi çalışma modunu korur', (tester) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 1);
    app.focus.setFocusMinutes(40);
    await _pumpApp(tester, app);
    await tester.pumpAndSettle();
    expect(find.text('40:00'), findsOneWidget);
    expect(app.focus.mode, 'focus');
  });

  testWidgets('onboarding profili kaydeder', (tester) async {
    final app = _buildApp();
    _setMobileSurface(tester);
    await tester.pumpWidget(
      AppScope(
        notifier: app,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ad soyad'),
      'Mehmet Kaya',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hedef sıralama'),
      '4500',
    );
    await tester.scrollUntilVisible(
      find.text('Başlayalım'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Başlayalım'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlayalım'));
    // Not pumpAndSettle: after submit the button shows an indefinite spinner
    // (in the real app routing unmounts this screen). A few pumps are enough to
    // run completeOnboarding and deliver the profile stream update.
    await tester.pump();
    await tester.pump();

    expect(app.profile.onboardingCompleted, isTrue);
    expect(app.profile.profile.userName, 'Mehmet Kaya');
    expect(app.profile.profile.targetRank, 4500);

    // Unmount so the submit-button's indefinite spinner ticker stops and does
    // not leak into the next test.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('boş program günü empty-state gösterir', (tester) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 3);
    await _pumpApp(tester, app);
    expect(find.text('Bu gün için görev yok'), findsOneWidget);
  });

  testWidgets('programa görev eklenir', (tester) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 3);
    await _pumpApp(tester, app);

    await tester.tap(find.text('Görev ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Fonksiyon tekrarı',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Fonksiyon tekrarı'), findsOneWidget);
    expect(app.schedule.selectedDayTasks.single.title, 'Fonksiyon tekrarı');
  });

  testWidgets('boş analiz empty-state gösterir ve deneme formu açılır', (
    tester,
  ) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 2);
    await _pumpApp(tester, app);
    expect(find.text('Henüz TYT denemesi eklemedin.'), findsOneWidget);

    await tester.tap(find.byTooltip('Deneme ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Deneme ekle'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Kaydet'), findsOneWidget);
  });

  testWidgets('çekmece profili açar ve kaydeder', (tester) async {
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app);

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
    expect(app.profile.profile.userName, 'Ayşe Demir');
  });

  testWidgets('hafta okları gerçek tarihi değiştirir', (tester) async {
    final app = _buildApp(profile: _onboarded(), initialTab: 3);
    final firstWeek = app.schedule.weekStart;
    await _pumpApp(tester, app);
    await tester.tap(find.byTooltip('Sonraki hafta'));
    await tester.pumpAndSettle();
    expect(app.schedule.weekStart, firstWeek.add(const Duration(days: 7)));
    await tester.tap(find.byTooltip('Önceki hafta'));
    await tester.pumpAndSettle();
    expect(app.schedule.weekStart, firstWeek);
  });

  testWidgets('asistan hızlı soruya yanıt üretir', (tester) async {
    final app = _buildApp(profile: _onboarded());
    await _pumpApp(tester, app, screen: 'assistant');
    expect(find.text('YKS Asistanına hoş geldin'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Deneme netlerimi yorumla');
    await tester.tap(find.byTooltip('Gönder'));
    await tester.pump(); // user message + typing indicator
    await tester.pump(const Duration(milliseconds: 700)); // fire delayed reply
    await tester.pumpAndSettle();
    expect(app.coach.messages.length, greaterThanOrEqualTo(2));
    expect(app.coach.messages.last.fromUser, isFalse);
    expect(find.textContaining('Analiz'), findsWidgets);
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
