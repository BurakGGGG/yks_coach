import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  static const subjects = [
    'Matematik - Limit & Türev',
    'Türkçe - Paragraf Soru Çözümü',
    'Fizik - Elektromanyetizma',
    'Kimya - Organik Kimya',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final total = switch (state.timerMode) {
      'shortBreak' => 5 * 60,
      'longBreak' => 15 * 60,
      _ => state.focusMinutes * 60,
    };
    final value = total == 0 ? 0.0 : state.remainingSeconds / total;
    final subjectOptions = {...subjects, state.focusSubject}.toList();

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
                  initialValue: state.focusSubject,
                  isExpanded: true,
                  items: subjectOptions
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => state.selectFocusSubject(value!),
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
            selected: {state.timerMode},
            onSelectionChanged: (value) => state.setTimerMode(value.first),
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
                          backgroundColor: scheme.primary.withValues(
                            alpha: .12,
                          ),
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
                        key: ValueKey(state.remainingSeconds),
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
                        Text(switch (state.timerMode) {
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
                onPressed: state.resetTimer,
                icon: const Icon(Icons.replay),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: state.toggleTimer,
                icon: Icon(state.timerRunning ? Icons.pause : Icons.play_arrow),
                label: Text(state.timerRunning ? 'Duraklat' : 'Başla'),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                tooltip: 'Sayaç ayarları',
                onPressed: () => _showSettings(context, state),
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
                            color:
                                index < state.completedFocusSessions.clamp(0, 5)
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
                    'Toplam Süre',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _durationLabel(state.totalFocusMinutes),
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

  Future<void> _showSettings(BuildContext context, AppState state) async {
    double minutes = state.focusMinutes.toDouble();
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
    if (result != null) state.setFocusMinutes(result);
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '${remaining}d';
    if (remaining == 0) return '${hours}s';
    return '${hours}s ${remaining}d';
  }
}
