import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/focus_controller.dart';
import '../widgets/common.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  static const _baseSubjects = [
    'Matematik',
    'Geometri',
    'Türkçe',
    'Edebiyat',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
    'İngilizce',
  ];

  @override
  Widget build(BuildContext context) {
    final focus = AppScope.of(context).focus;
    final scheme = Theme.of(context).colorScheme;
    final minutes = focus.remainingSeconds ~/ 60;
    final seconds = focus.remainingSeconds % 60;
    final total = focus.totalSeconds;
    final value = total == 0 ? 0.0 : focus.remainingSeconds / total;
    final options = <String>{
      ..._baseSubjects,
      if (focus.subject.isNotEmpty) focus.subject,
    }.toList();

    return PagePadding(
      child: Column(
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÇALIŞMA KONUSU',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: focus.subject.isEmpty ? null : focus.subject,
                  isExpanded: true,
                  hint: const Text('Konu seç'),
                  items: options
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      value == null ? null : focus.selectSubject(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'focus', label: Text('Çalışma')),
              ButtonSegment(value: 'shortBreak', label: Text('Kısa Ara')),
              ButtonSegment(value: 'longBreak', label: Text('Uzun Ara')),
            ],
            selected: {focus.mode},
            onSelectionChanged: (value) => focus.setMode(value.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 256,
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: value),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) =>
                        CircularProgressIndicator(
                          value: animatedValue,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: scheme.primary.withValues(alpha: .12),
                        ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: .98, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        key: ValueKey(focus.remainingSeconds),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 64, height: 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text(switch (focus.mode) {
                          'shortBreak' => 'Kısa Mola',
                          'longBreak' => 'Uzun Mola',
                          _ => 'Odaklanma Modu',
                        }, style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Sıfırla',
                onPressed: focus.reset,
                icon: const Icon(Icons.replay),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: focus.toggleTimer,
                icon: Icon(focus.running ? Icons.pause : Icons.play_arrow),
                label: Text(focus.running ? 'Duraklat' : 'Başla'),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                tooltip: 'Sayaç ayarları',
                onPressed: () => _showSettings(context, focus),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugünkü Pomodorolar',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < focus.todaySessionCount.clamp(0, 5)
                                ? scheme.secondary
                                : scheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bugünkü Süre',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _durationLabel(focus.todayMinutes),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings(BuildContext context, FocusController focus) async {
    double minutes = focus.focusMinutes.toDouble();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Odak süresi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.round()} dakika',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Slider(
                value: minutes,
                min: 5,
                max: 60,
                divisions: 11,
                label: '${minutes.round()}',
                onChanged: (value) => setLocalState(() => minutes = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, minutes.round()),
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
    if (result != null) focus.setFocusMinutes(result);
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '${remaining}d';
    if (remaining == 0) return '${hours}s';
    return '${hours}s ${remaining}d';
  }
}
