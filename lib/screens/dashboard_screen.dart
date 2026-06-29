import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final completed = state.tasks.where((task) => task.completed).length;
    final progress = state.tasks.isEmpty ? 0.0 : completed / state.tasks.length;
    final nextTask = state.tasks.where((task) => !task.completed).firstOrNull;

    return PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günaydın, ${state.userName.split(' ').first}.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Bugün hedeflerine bir adım daha yakınsın.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            onTap: () => state.setTab(3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugünkü Hedef: %${(progress * 100).round()}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed/${state.tasks.length} görev tamamlandı',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: animatedValue,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: scheme.surfaceContainerHigh,
                        ),
                        Text(
                          '%${(animatedValue * 100).round()}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.timer_outlined,
                  value: '4s',
                  label: 'Toplam\nÇalışma',
                  color: scheme.primary,
                  onTap: () => state.setTab(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.checklist,
                  value: '${state.dailyQuestionGoal}',
                  label: 'Çözülen\nSoru',
                  color: scheme.secondary,
                  onTap: () => state.setTab(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.psychology_outlined,
                  value: '85%',
                  label: 'Odak\nSüresi',
                  color: scheme.tertiary,
                  onTap: () => state.setTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Sıradaki Görev'),
          const SizedBox(height: 8),
          if (nextTask != null)
            SurfaceCard(
              border: true,
              onTap: () => state.startTask(nextTask),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calculate_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextTask.subject,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          nextTask.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(label: Text(nextTask.time.split(' - ').first)),
                ],
              ),
            )
          else
            const SurfaceCard(child: Text('Bugünkü tüm görevler tamamlandı.')),
          const SizedBox(height: 24),
          const SectionTitle('Haftalık Aktivite (Saat)'),
          const SizedBox(height: 8),
          const SurfaceCard(child: _WeeklyChart()),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();
  @override
  Widget build(BuildContext context) {
    const values = [2.0, 3.5, 5.0, 6.0, 3.0, 1.5, .5];
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final active = index == 3;
          return Expanded(
            child: Tooltip(
              message: '${values[index]} saat',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: values[index]),
                      duration: Duration(milliseconds: 450 + index * 70),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) => Container(
                        height: animatedValue * 18,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.primary.withValues(
                                  alpha: .18 + index * .06,
                                ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
