import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

/// First-run profile setup. Shown once, before the main shell, when the user's
/// `onboardingCompleted` flag is false. Writes the real profile — no demo data
/// is ever seeded.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;

  late String _name;
  String _grade = '12. Sınıf';
  String _field = 'Sayısal';
  String _university = '';
  String _department = '';
  String _rank = '';
  double _questionGoal = 80;
  double _studyMinutes = 180;

  static const _grades = [
    '9. Sınıf',
    '10. Sınıf',
    '11. Sınıf',
    '12. Sınıf',
    'Mezun',
  ];
  static const _fields = ['Sayısal', 'Eşit Ağırlık', 'Sözel', 'Dil'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _name = AppScope.of(context).profile.suggestedName;
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final app = AppScope.of(context);
      await app.completeOnboarding(
        const UserProfile().copyWith(
          userName: _name.trim(),
          grade: _grade,
          studyField: _field,
          targetUniversity: _university.trim(),
          targetDepartment: _department.trim(),
          targetRank: int.parse(_rank),
          dailyQuestionGoal: _questionGoal.round(),
          dailyStudyMinutes: _studyMinutes.round(),
        ),
      );
      // Routing reacts to onboardingCompleted; nothing else to do here.
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          'Profil kurulumu kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 48,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Zihin Rehberi’ne hoş geldin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sana özel bir çalışma deneyimi için birkaç bilgi alalım.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Seni tanıyalım'),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Ad soyad',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 3
                              ? 'Ad soyad gerekli'
                              : null,
                          onChanged: (value) => _name = value,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _grade,
                          decoration: const InputDecoration(
                            labelText: 'Sınıf',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: _grades
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _grade = value!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _field,
                          decoration: const InputDecoration(
                            labelText: 'Alan',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _fields
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _field = value!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('YKS hedefin'),
                        const SizedBox(height: 16),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Hedef üniversite',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          onChanged: (value) => _university = value,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Hedef bölüm',
                            prefixIcon: Icon(Icons.workspace_premium_outlined),
                          ),
                          onChanged: (value) => _department = value,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Hedef sıralama',
                            prefixIcon: Icon(Icons.emoji_events_outlined),
                          ),
                          validator: (value) {
                            final rank = int.tryParse(value ?? '');
                            return rank == null || rank < 1
                                ? 'Geçerli bir sıralama gir'
                                : null;
                          },
                          onChanged: (value) => _rank = value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Günlük hedeflerin'),
                        const SizedBox(height: 8),
                        Text(
                          '${_questionGoal.round()} soru / gün',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: scheme.primary),
                        ),
                        Slider(
                          value: _questionGoal,
                          min: 20,
                          max: 300,
                          divisions: 28,
                          label: '${_questionGoal.round()}',
                          onChanged: (value) =>
                              setState(() => _questionGoal = value),
                        ),
                        Text(
                          '${(_studyMinutes / 60).toStringAsFixed(1)} saat çalışma / gün',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: scheme.secondary),
                        ),
                        Slider(
                          value: _studyMinutes,
                          min: 30,
                          max: 600,
                          divisions: 19,
                          label: '${_studyMinutes.round()} dk',
                          onChanged: (value) =>
                              setState(() => _studyMinutes = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_saving ? 'Hazırlanıyor...' : 'Başlayalım'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
