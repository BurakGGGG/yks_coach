import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tasks = state.selectedDayTasks;
    final completed = tasks.where((task) => task.completed).length;
    final ratio = tasks.isEmpty ? 0.0 : completed / tasks.length;
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum'];
    final days = List.generate(
      5,
      (index) => (dayNames[index], state.weekStart.add(Duration(days: index))),
    );

    return PagePadding(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Önceki hafta',
                onPressed: () => state.changeWeek(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _monthLabel(state.weekStart),
                  key: ValueKey(state.weekStart),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Sonraki hafta',
                onPressed: () => state.changeWeek(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(days.length, (index) {
              final selected = state.selectedDay == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => state.selectDay(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              days[index].$1,
                              style: TextStyle(
                                color: selected
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              days[index].$2.day.toString(),
                              style: Theme.of(context).textTheme.titleLarge
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
                        _selectedDayLabel(state.selectedDate),
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
              onPressed: () => _showAddTask(context, state),
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
                    key: ValueKey(state.selectedDate),
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
                          onPressed: () => _showAddTask(context, state),
                          icon: const Icon(Icons.add),
                          label: const Text('Görev ekle'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: ValueKey(state.selectedDate),
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
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _selectedDayLabel(DateTime date) {
    const dayNames = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return '${dayNames[date.weekday - 1].toUpperCase()} · ${date.day}';
  }

  Future<void> _showAddTask(BuildContext context, AppState state) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final time = TextEditingController(text: '17:00 - 18:00');
    String subject = 'Matematik';
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yeni görev'),
              const SizedBox(height: 2),
              Text(
                _selectedDayLabel(state.selectedDate),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: subject,
                  decoration: const InputDecoration(labelText: 'Ders'),
                  items:
                      const [
                            'Matematik',
                            'Türkçe',
                            'Geometri',
                            'Fizik',
                            'Kimya',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
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
                  controller: time,
                  readOnly: true,
                  onTap: () => _pickTaskTime(context, time),
                  decoration: const InputDecoration(
                    labelText: 'Saat',
                    suffixIcon: Icon(Icons.schedule_outlined),
                  ),
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
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    if (added == true && title.text.trim().isNotEmpty) {
      state.addTask(
        StudyTask(
          subject: subject,
          title: title.text.trim(),
          time: time.text.trim(),
          color: const Color(0xFF2563EB),
          scheduledDate: state.selectedDate,
        ),
      );
      if (context.mounted) AppSnack.show(context, 'Görev programa eklendi');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    time.dispose();
  }

  Future<void> _pickTaskTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
      helpText: 'Başlangıç saati',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
      helpText: 'Bitiş saati',
    );
    if (end == null || !context.mounted) return;
    controller.text = '${start.format(context)} - ${end.format(context)}';
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final StudyTask task;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
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
              onChanged: (_) => state.toggleTask(task),
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
                        task.time,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.completed
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (task.detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.detail!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Odak oturumu başlat',
              onPressed: () => state.startTask(task),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
