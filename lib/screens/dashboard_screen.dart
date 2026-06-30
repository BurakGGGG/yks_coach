import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profile = app.profile.profile;
    final stats = app.dashboardStats;

    final now = DateTime.now();
    final todayTasks = app.schedule.tasks
        .where((task) => _sameDay(task.scheduledDate, now))
        .toList();
    final nextTask = todayTasks.where((task) => !task.completed).firstOrNull;
    final firstName = profile.userName.trim().isEmpty
        ? 'Öğrenci'
        : profile.userName.trim().split(' ').first;

    return PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merhaba, $firstName.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Bugün hedeflerine bir adım daha yakınsın.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            onTap: () => app.setTab(3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugünkü Hedef: %${(stats.todayCompletionRatio * 100).round()}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayTasks.isEmpty
                            ? 'Bugün için henüz görev eklemedin'
                            : '${stats.todayCompletedTasks}/${stats.todayTotalTasks} görev tamamlandı',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: stats.todayCompletionRatio),
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
                  value: _durationLabel(stats.todayStudyMinutes),
                  label: 'Bugünkü\nÇalışma',
                  color: scheme.primary,
                  onTap: () => app.setTab(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.checklist,
                  value:
                      '${stats.todayCompletedTasks}/${stats.todayTotalTasks}',
                  label: 'Tamamlanan\nGörev',
                  color: scheme.secondary,
                  onTap: () => app.setTab(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  icon: Icons.psychology_outlined,
                  value: '${stats.todayFocusSessions}',
                  label: 'Pomodoro\nOturumu',
                  color: scheme.tertiary,
                  onTap: () => app.setTab(1),
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
              onTap: () => app.startTaskFocus(nextTask.subject, nextTask.title),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: nextTask.color.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: nextTask.color,
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
                  Chip(label: Text(nextTask.startLabel)),
                ],
              ),
            )
          else
            SurfaceCard(
              border: true,
              child: Row(
                children: [
                  Icon(Icons.event_available_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      todayTasks.isEmpty
                          ? 'Bugün için Program sekmesinden görev ekleyebilirsin.'
                          : 'Bugünkü tüm görevleri tamamladın. Harikasın!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => app.setTab(3),
                    child: const Text('Program'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const SectionTitle('Haftalık Aktivite (Saat)'),
          const SizedBox(height: 8),
          SurfaceCard(child: _WeeklyChart(hours: stats.weeklyStudyHours)),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _durationLabel(int minutes) {
    if (minutes <= 0) return '0dk';
    if (minutes < 60) return '${minutes}dk';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}s';
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
  const _WeeklyChart({required this.hours});

  final List<double> hours;

  @override
  Widget build(BuildContext context) {
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final scheme = Theme.of(context).colorScheme;
    final maxValue = hours.fold<double>(0, (m, v) => v > m ? v : m);
    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);

    if (maxValue == 0) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Bu hafta henüz çalışma kaydın yok.\nOdak sekmesinden ilk oturumunu başlat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(hours.length, (index) {
          final active = index == todayIndex;
          final value = hours[index];
          return Expanded(
            child: Tooltip(
              message: '${value.toStringAsFixed(1)} saat',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value),
                      duration: Duration(milliseconds: 450 + index * 70),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) => Container(
                        height: maxValue == 0
                            ? 2
                            : (118 * animatedValue / maxValue).clamp(2, 118),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: .35),
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
