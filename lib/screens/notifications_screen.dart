import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              AnimatedEntrance(
                child: SurfaceCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.today_outlined),
                        title: const Text('Günlük plan hatırlatması'),
                        subtitle: const Text(
                          'Her gün çalışma planını hatırlatır.',
                        ),
                        value: state.dailyReminder,
                        onChanged: (value) =>
                            state.updateNotification(daily: value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.task_alt_outlined),
                        title: const Text('Görev başlangıçları'),
                        subtitle: const Text('Görevden 10 dakika önce uyarır.'),
                        value: state.taskReminder,
                        onChanged: (value) =>
                            state.updateNotification(task: value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('Motivasyon mesajları'),
                        subtitle: const Text(
                          'Çalışma serine göre kısa öneriler gönderir.',
                        ),
                        value: state.motivationReminder,
                        onChanged: (value) =>
                            state.updateNotification(motivation: value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.analytics_outlined),
                        title: const Text('Deneme değerlendirmesi'),
                        subtitle: const Text(
                          'Yeni analiz hazır olduğunda haber verir.',
                        ),
                        value: state.examReminder,
                        onChanged: (value) =>
                            state.updateNotification(exam: value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                onTap: () => _pickTime(context, state),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hatırlatma saati'),
                          Text('Günlük özet bu saatte gönderilir.'),
                        ],
                      ),
                    ),
                    Text(
                      state.reminderTime.format(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    AppSnack.show(context, 'Bildirim tercihleri kaydedildi'),
                icon: const Icon(Icons.check),
                label: const Text('Tercihleri kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, AppState state) async {
    final time = await showTimePicker(
      context: context,
      initialTime: state.reminderTime,
    );
    if (time != null) state.updateNotification(time: time);
  }
}
