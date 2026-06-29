import 'package:flutter/material.dart';

import '../models/practice_exam.dart';
import '../state/analytics.dart';
import '../state/app_controller.dart';
import '../state/exam_controller.dart';
import '../widgets/common.dart';

const _examSubjects = {
  'TYT': ['Türkçe', 'Sosyal', 'Matematik', 'Fen'],
  'AYT': [
    'Matematik',
    'Edebiyat',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
  ],
};

const _subjectColors = <String, Color>{
  'Türkçe': Color(0xFF8B5CF6),
  'Sosyal': Color(0xFFF59E0B),
  'Matematik': Color(0xFF2563EB),
  'Fen': Color(0xFF10B981),
  'Edebiyat': Color(0xFF7C3AED),
  'Fizik': Color(0xFF0EA5E9),
  'Kimya': Color(0xFFEF4444),
  'Biyoloji': Color(0xFF22C55E),
  'Tarih': Color(0xFFF59E0B),
  'Coğrafya': Color(0xFFD97706),
};

Color _colorFor(String subject) =>
    _subjectColors[subject] ?? const Color(0xFF2563EB);

String _netLabel(double net) =>
    net.toStringAsFixed(net % 1 == 0 ? 0 : (net * 100 % 10 == 0 ? 1 : 2));

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exam = AppScope.of(context).exams;
    final scheme = Theme.of(context).colorScheme;
    final stats = exam.stats;
    final visible = exam.showAll ? stats.exams : stats.exams.take(2).toList();

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
                onPressed: () => _showAddExam(context, exam),
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
                            'Son ${stats.netSeries.length} Deneme (${exam.examType})',
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
                      selected: {exam.examType},
                      onSelectionChanged: (value) =>
                          exam.setExamType(value.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _NetChart(values: stats.netSeries, emptyType: exam.examType),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up,
                  value: _netLabel(stats.averageNet),
                  label: 'Net Ortalaması',
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.task_alt,
                  value: '${stats.examCount}',
                  label: 'Çözülen Deneme',
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.warning_amber,
                  value: stats.weakest?.subject ?? '—',
                  label: stats.weakest == null
                      ? 'Zayıf Ders'
                      : '%${(stats.weakest!.successRate * 100).round()} Başarı',
                  color: scheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle('Ders Bazlı Analiz (${exam.examType})'),
          const SizedBox(height: 8),
          if (stats.subjects.isEmpty)
            SurfaceCard(
              border: true,
              child: Text(
                'Bu tür için henüz veri yok. Bir deneme ekleyince ders bazlı '
                'analizin burada görünecek.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            SurfaceCard(
              child: Column(
                children: stats.subjects
                    .map((subject) => _SubjectRow(stat: subject))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          SectionTitle(
            'Son Denemeler',
            action: stats.exams.length > 2
                ? TextButton(
                    onPressed: exam.toggleShowAll,
                    child: Text(exam.showAll ? 'Daha Az' : 'Tümünü Gör'),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            SurfaceCard(
              border: true,
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Henüz ${exam.examType} denemesi eklemedin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAddExam(context, exam),
                    child: const Text('Ekle'),
                  ),
                ],
              ),
            )
          else
            ...visible.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  border: true,
                  onTap: () => _showExamDetail(context, exam, item),
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
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _dateLabel(item.takenAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _netLabel(item.totalNet),
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: scheme.primary),
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

  Future<void> _showAddExam(BuildContext context, ExamController controller) async {
    final exam = await showModalBottomSheet<PracticeExam>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ExamForm(initialType: controller.examType),
      ),
    );
    if (exam != null) {
      await controller.addExam(exam);
      if (context.mounted) AppSnack.show(context, 'Deneme analize eklendi');
    }
  }

  Future<void> _showExamDetail(
    BuildContext context,
    ExamController controller,
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
            const SizedBox(height: 4),
            Text('${_dateLabel(exam.takenAt)} · ${exam.type}'),
            const SizedBox(height: 16),
            Text(
              '${_netLabel(exam.totalNet)} net',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...exam.subjects.map(
              (subject) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(subject.subject)),
                    Text(
                      '${subject.correct} D / ${subject.wrong} Y / ${subject.blank} B',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _netLabel(subject.net),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
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
    if (remove == true) {
      await controller.removeExam(exam.id);
      if (context.mounted) AppSnack.show(context, 'Deneme silindi');
    }
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Modal form that collects a practice exam with per-subject D/Y/B counts.
class _ExamForm extends StatefulWidget {
  const _ExamForm({required this.initialType});

  final String initialType;

  @override
  State<_ExamForm> createState() => _ExamFormState();
}

class _ExamFormState extends State<_ExamForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late String _type = widget.initialType;
  DateTime _date = DateTime.now();

  // One (correct, wrong, blank) controller triple per possible subject.
  final _fields = <String, List<TextEditingController>>{};

  @override
  void initState() {
    super.initState();
    final all = {..._examSubjects['TYT']!, ..._examSubjects['AYT']!};
    for (final subject in all) {
      _fields[subject] = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final triple in _fields.values) {
      for (final controller in triple) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  int _parse(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final subjects = <ExamSubjectResult>[];
    for (final subject in _examSubjects[_type]!) {
      final triple = _fields[subject]!;
      final result = ExamSubjectResult(
        subject: subject,
        correct: _parse(triple[0]),
        wrong: _parse(triple[1]),
        blank: _parse(triple[2]),
      );
      if (result.questionCount > 0) subjects.add(result);
    }
    if (subjects.isEmpty) {
      AppSnack.show(context, 'En az bir ders için sonuç gir');
      return;
    }
    Navigator.pop(
      context,
      PracticeExam(name: _name.text.trim(), type: _type, takenAt: _date, subjects: subjects),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _examSubjects[_type]!;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        shrinkWrap: true,
        children: [
          Text('Deneme ekle', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'TYT', label: Text('TYT')),
              ButtonSegment(value: 'AYT', label: Text('AYT')),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Deneme adı'),
            validator: (value) => value == null || value.trim().length < 3
                ? 'Deneme adını gir'
                : null,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text('Tarih: ${_date.day}.${_date.month}.${_date.year}'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(flex: 4, child: Text('Ders')),
              Expanded(child: Text('D', textAlign: TextAlign.center)),
              Expanded(child: Text('Y', textAlign: TextAlign.center)),
              Expanded(child: Text('B', textAlign: TextAlign.center)),
            ],
          ),
          const Divider(),
          ...subjects.map((subject) => _subjectRow(subject)),
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text('Kaydet')),
        ],
      ),
    );
  }

  Widget _subjectRow(String subject) {
    final triple = _fields[subject]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _colorFor(subject),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(subject, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          for (final controller in triple)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NetChart extends StatelessWidget {
  const _NetChart({required this.values, required this.emptyType});

  final List<double> values;
  final String emptyType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (values.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Henüz $emptyType denemesi eklenmedi.',
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
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
  const _SubjectRow({required this.stat});
  final SubjectStat stat;
  @override
  Widget build(BuildContext context) {
    final color = _colorFor(stat.subject);
    return Padding(
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
              Expanded(child: Text(stat.subject)),
              Text(
                stat.detailLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            value: stat.successRate,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ],
      ),
    );
  }
}
