import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/common.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _initialized = false;
  late double _questions;
  late double _minutes;
  final Set<String> _prioritySubjects = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = AppScope.of(context).profile.profile;
    _questions = profile.dailyQuestionGoal.toDouble();
    _minutes = profile.dailyStudyMinutes.toDouble();
    _prioritySubjects.addAll(profile.prioritySubjects);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileController = AppScope.of(context).profile;
    final profile = profileController.profile;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hedeflerim')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              AnimatedEntrance(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hedef sıralama',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                            Text(
                              profile.targetRank == 0
                                  ? 'Belirtilmedi'
                                  : '${profile.targetRank}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                            Text(
                              [profile.targetUniversity, profile.targetDepartment]
                                  .where((value) => value.isNotEmpty)
                                  .join(' · '),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Günlük soru hedefi'),
                    const SizedBox(height: 8),
                    Text(
                      '${_questions.round()} soru',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                    Slider(
                      value: _questions,
                      min: 20,
                      max: 300,
                      divisions: 28,
                      label: '${_questions.round()}',
                      onChanged: (value) => setState(() => _questions = value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [Text('20'), Text('300')],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Günlük çalışma süresi'),
                    const SizedBox(height: 8),
                    Text(
                      '${(_minutes / 60).toStringAsFixed(1)} saat',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: scheme.secondary),
                    ),
                    Slider(
                      value: _minutes,
                      min: 30,
                      max: 600,
                      divisions: 19,
                      label: '${_minutes.round()} dk',
                      onChanged: (value) => setState(() => _minutes = value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [Text('30 dk'), Text('10 saat')],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Öncelikli dersler'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    const [
                      'Matematik',
                      'Türkçe',
                      'Fizik',
                      'Kimya',
                      'Biyoloji',
                      'Geometri',
                    ].map((subject) {
                      final selected = _prioritySubjects.contains(subject);
                      return FilterChip(
                        label: Text(subject),
                        selected: selected,
                        onSelected: (value) => setState(
                          () => value
                              ? _prioritySubjects.add(subject)
                              : _prioritySubjects.remove(subject),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  profileController.updateGoals(
                    questions: _questions.round(),
                    studyMinutes: _minutes.round(),
                    subjects: _prioritySubjects.toList(),
                  );
                  AppSnack.show(context, 'Günlük hedeflerin güncellendi');
                },
                icon: const Icon(Icons.check),
                label: const Text('Hedefleri kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
