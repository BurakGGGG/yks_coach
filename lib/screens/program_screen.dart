import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../state/app_controller.dart';
import '../state/schedule_controller.dart';
import '../widgets/common.dart';

const _subjectColors = <String, Color>{
  'Matematik': Color(0xFF2563EB),
  'Geometri': Color(0xFF10B981),
  'Türkçe': Color(0xFF8B5CF6),
  'Edebiyat': Color(0xFF7C3AED),
  'Fizik': Color(0xFF0EA5E9),
  'Kimya': Color(0xFFEF4444),
  'Biyoloji': Color(0xFF22C55E),
  'Tarih': Color(0xFFF59E0B),
  'Coğrafya': Color(0xFFD97706),
  'Felsefe': Color(0xFF6366F1),
  'İngilizce': Color(0xFF14B8A6),
  'Diğer': Color(0xFF64748B),
};

List<String> get _subjects => _subjectColors.keys.toList();

Color _colorFor(String subject) => _subjectColors[subject] ?? const Color(0xFF2563EB);

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final schedule = app.schedule;
    final scheme = Theme.of(context).colorScheme;
    final tasks = schedule.selectedDayTasks;
    final completed = tasks.where((task) => task.completed).length;
    final ratio = tasks.isEmpty ? 0.0 : completed / tasks.length;
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final days = List.generate(
      7,
      (index) => (dayNames[index], schedule.weekStart.add(Duration(days: index))),
    );

    return PagePadding(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Önceki hafta',
                onPressed: () => schedule.changeWeek(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _monthLabel(schedule.weekStart),
                  key: ValueKey(schedule.weekStart),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Sonraki hafta',
                onPressed: () => schedule.changeWeek(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(days.length, (index) {
              final selected = schedule.selectedDay == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => schedule.selectDay(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              days[index].$1,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              days[index].$2.day.toString(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: selected
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDayLabel(schedule.selectedDate),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ),
                    Text(
                      '$completed/${tasks.length} Görev',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '%${(ratio * 100).round()} Tamamlandı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                AnimatedProgressBar(
                  value: ratio,
                  backgroundColor: scheme.surfaceContainerHigh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            'Program',
            action: TextButton.icon(
              onPressed: () => _showTaskDialog(context, schedule),
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: tasks.isEmpty
                ? SurfaceCard(
                    key: ValueKey(schedule.selectedDate),
                    border: true,
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 36,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu gün için görev yok',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yeni bir çalışma ekleyerek programını oluştur.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _showTaskDialog(context, schedule),
                          icon: const Icon(Icons.add),
                          label: const Text('Görev ekle'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: ValueKey(schedule.selectedDate),
                    children: tasks.indexed
                        .map(
                          (entry) => AnimatedEntrance(
                            delay: Duration(milliseconds: 45 * entry.$1),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TaskCard(task: entry.$2),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _selectedDayLabel(DateTime date) {
    const dayNames = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
    ];
    return '${dayNames[date.weekday - 1].toUpperCase()} · ${date.day}';
  }
}

Future<void> _showTaskDialog(
  BuildContext context,
  ScheduleController schedule, {
  StudyTask? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController(text: existing?.title ?? '');
  final detail = TextEditingController(text: existing?.detail ?? '');
  String subject = existing?.subject ?? 'Matematik';
  TimeOfDay start = existing == null
      ? const TimeOfDay(hour: 17, minute: 0)
      : TimeOfDay(hour: existing.startMinutes ~/ 60, minute: existing.startMinutes % 60);
  TimeOfDay end = existing == null
      ? const TimeOfDay(hour: 18, minute: 0)
      : TimeOfDay(hour: existing.endMinutes ~/ 60, minute: existing.endMinutes % 60);
  final date = existing?.scheduledDate ?? schedule.selectedDate;

  int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocalState) {
        Future<void> pickStart() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: start,
            helpText: 'Başlangıç saati',
          );
          if (picked != null) {
            setLocalState(() {
              start = picked;
              if (minutesOf(end) <= minutesOf(start)) {
                end = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
              }
            });
          }
        }

        Future<void> pickEnd() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: end,
            helpText: 'Bitiş saati',
          );
          if (picked != null) setLocalState(() => end = picked);
        }

        return AlertDialog(
          title: Text(existing == null ? 'Yeni görev' : 'Görevi düzenle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: subject,
                    decoration: const InputDecoration(labelText: 'Ders'),
                    items: _subjects
                        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setLocalState(() => subject = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: title,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Görev adı'),
                    validator: (value) => value == null || value.trim().length < 3
                        ? 'Görev adını gir'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detail,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (isteğe bağlı)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickStart,
                          icon: const Icon(Icons.schedule_outlined, size: 18),
                          label: Text(start.format(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickEnd,
                          icon: const Icon(Icons.schedule, size: 18),
                          label: Text(end.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (minutesOf(end) <= minutesOf(start)) {
                  AppSnack.show(context, 'Bitiş saati başlangıçtan sonra olmalı');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(existing == null ? 'Ekle' : 'Kaydet'),
            ),
          ],
        );
      },
    ),
  );

  if (saved == true) {
    final task = StudyTask(
      id: existing?.id ?? '',
      subject: subject,
      title: title.text.trim(),
      scheduledDate: date,
      startMinutes: minutesOf(start),
      endMinutes: minutesOf(end),
      color: _colorFor(subject),
      detail: detail.text.trim().isEmpty ? null : detail.text.trim(),
      status: existing?.status ?? TaskStatus.planned,
    );
    await schedule.addTask(task);
    if (context.mounted) {
      AppSnack.show(
        context,
        existing == null ? 'Görev programa eklendi' : 'Görev güncellendi',
      );
    }
  }
  // Let the dialog's dismiss animation finish before disposing the controllers,
  // otherwise the still-mounted TextFields read a disposed controller.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  title.dispose();
  detail.dispose();
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final schedule = app.schedule;
    return AnimatedOpacity(
      opacity: task.completed ? .68 : 1,
      duration: const Duration(milliseconds: 260),
      child: SurfaceCard(
        border: true,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (_) => schedule.toggleTask(task),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: task.color.withValues(alpha: .12),
                        side: BorderSide.none,
                        label: Text(
                          task.subject,
                          style: TextStyle(color: task.color),
                        ),
                      ),
                      Text(
                        task.timeLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (task.detail != null && task.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.detail!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            _TaskMenu(task: task, schedule: schedule, app: app),
          ],
        ),
      ),
    );
  }
}

class _TaskMenu extends StatelessWidget {
  const _TaskMenu({
    required this.task,
    required this.schedule,
    required this.app,
  });

  final StudyTask task;
  final ScheduleController schedule;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Görev işlemleri',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'focus':
            app.startTaskFocus(task.subject, task.title);
          case 'edit':
            await _showTaskDialog(context, schedule, existing: task);
          case 'delete':
            await schedule.deleteTask(task.id);
            if (context.mounted) AppSnack.show(context, 'Görev silindi');
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'focus',
          child: ListTile(
            leading: Icon(Icons.play_arrow_rounded),
            title: Text('Odakta başlat'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Düzenle'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Sil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
