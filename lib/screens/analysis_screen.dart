import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final filtered = state.exams
        .where((exam) => exam.type == state.examType)
        .toList();
    final visible = state.showAllExams ? filtered : filtered.take(2).toList();
    final average = filtered.isEmpty
        ? 0.0
        : filtered.map((exam) => exam.net).reduce((a, b) => a + b) /
              filtered.length;
    final chartValues = filtered.reversed.map((exam) => exam.net).toList();
    final weakSubject = state.examType == 'TYT' ? 'Fizik' : 'Kimya';
    final subjectRows = state.examType == 'TYT'
        ? const [
            ('Matematik', '28 Doğru / 4 Yanlış', .78, Color(0xFF2563EB)),
            ('Türkçe', '32 Doğru / 5 Yanlış', .84, Color(0xFF10B981)),
            ('Fen Bilimleri', '12 Doğru / 6 Yanlış', .52, Color(0xFFEF4444)),
            ('Sosyal Bilgiler', '15 Doğru / 2 Yanlış', .76, Color(0xFFF59E0B)),
          ]
        : const [
            ('Matematik', '24 Doğru / 7 Yanlış', .68, Color(0xFF2563EB)),
            ('Fizik', '9 Doğru / 4 Yanlış', .61, Color(0xFF0EA5E9)),
            ('Kimya', '7 Doğru / 5 Yanlış', .48, Color(0xFFEF4444)),
            ('Biyoloji', '10 Doğru / 2 Yanlış', .74, Color(0xFF10B981)),
          ];

    return PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deneme Analizi',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Gelişimini takip et ve eksiklerini gör.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () => _showAddExam(context, state),
                icon: const Icon(Icons.add),
                tooltip: 'Deneme ekle',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Gelişimi',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Son 10 Deneme (${state.examType})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'TYT', label: Text('TYT')),
                        ButtonSegment(value: 'AYT', label: Text('AYT')),
                      ],
                      selected: {state.examType},
                      onSelectionChanged: (value) =>
                          state.setExamType(value.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _NetChart(values: chartValues),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up,
                  value: average.toStringAsFixed(1),
                  label: 'Net Ortalaması',
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.task_alt,
                  value: '${filtered.length}',
                  label: 'Çözülen Deneme',
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.warning_amber,
                  value: weakSubject,
                  label: '%45 Başarı',
                  color: scheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle('Ders Bazlı Analiz (${state.examType})'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: subjectRows
                  .map(
                    (row) => _SubjectRow(
                      name: row.$1,
                      detail: row.$2,
                      value: row.$3,
                      color: row.$4,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            'Son Denemeler',
            action: filtered.length > 2
                ? TextButton(
                    onPressed: state.toggleAllExams,
                    child: Text(state.showAllExams ? 'Daha Az' : 'Tümünü Gör'),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          ...visible.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SurfaceCard(
                border: true,
                onTap: () => _showExamDetail(context, state, exam),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            exam.date,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      exam.net.toStringAsFixed(exam.net % 1 == 0 ? 0 : 1),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(width: 4),
                    Text('Net', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExam(BuildContext context, AppState state) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final net = TextEditingController();
    String type = state.examType;
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Deneme ekle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'TYT', label: Text('TYT')),
                    ButtonSegment(value: 'AYT', label: Text('AYT')),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setLocalState(() => type = value.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Deneme adı'),
                  validator: (value) => value == null || value.trim().length < 3
                      ? 'Deneme adını gir'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: net,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Net',
                    helperText: type == 'TYT' ? '0–120' : '0–80',
                  ),
                  validator: (value) {
                    final score = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    final max = type == 'TYT' ? 120 : 80;
                    if (score == null || score < 0 || score > max) {
                      return '0 ile $max arasında bir değer gir';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    final score = double.tryParse(net.text.replaceAll(',', '.'));
    if (added == true && score != null) {
      state.addExam(
        PracticeExam(
          name: name.text.trim(),
          date: 'Bugün',
          net: score,
          type: type,
        ),
      );
      if (context.mounted) AppSnack.show(context, 'Deneme analize eklendi');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    net.dispose();
  }

  Future<void> _showExamDetail(
    BuildContext context,
    AppState state,
    PracticeExam exam,
  ) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exam.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${exam.date} · ${exam.type}'),
            const SizedBox(height: 16),
            Text(
              '${exam.net} net',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Denemeyi sil'),
              ),
            ),
          ],
        ),
      ),
    );
    if (remove == true && context.mounted) {
      state.removeExam(exam);
      AppSnack.show(context, 'Deneme silindi');
    }
  }
}

class _NetChart extends StatelessWidget {
  const _NetChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (values.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Henüz ${AppScope.of(context).examType} denemesi eklenmedi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          values.length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: '${values[index].round()} net',
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: values[index]),
                  duration: Duration(milliseconds: 420 + index * 55),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) => Container(
                    height: maxValue == 0
                        ? 4
                        : 112 * (animatedValue / maxValue).clamp(.04, 1),
                    decoration: BoxDecoration(
                      color: index == values.length - 1
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: .28 + index * .04),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    ),
  );
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.name,
    required this.detail,
    required this.value,
    required this.color,
  });
  final String name;
  final String detail;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(name)),
            Text(detail, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedProgressBar(
          value: value,
          minHeight: 6,
          color: color,
          backgroundColor: color.withValues(alpha: .12),
        ),
      ],
    ),
  );
}
