import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final notifications = app.notifications;
    final profile = app.profile.profile;
    final enabled = notifications.supported && !notifications.busy;
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
                        value: profile.dailyReminder,
                        onChanged: enabled
                            ? (value) => _update(context, app, daily: value)
                            : null,
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.task_alt_outlined),
                        title: const Text('Görev başlangıçları'),
                        subtitle: const Text('Görevden 10 dakika önce uyarır.'),
                        value: profile.taskReminder,
                        onChanged: enabled
                            ? (value) => _update(context, app, task: value)
                            : null,
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('Motivasyon mesajları'),
                        subtitle: const Text(
                          'Çalışma serine göre kısa öneriler gönderir.',
                        ),
                        value: profile.motivationReminder,
                        onChanged: enabled
                            ? (value) =>
                                  _update(context, app, motivation: value)
                            : null,
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.analytics_outlined),
                        title: const Text('Deneme değerlendirmesi'),
                        subtitle: const Text(
                          'Yeni analiz hazır olduğunda haber verir.',
                        ),
                        value: profile.examReminder,
                        onChanged: enabled
                            ? (value) => _update(context, app, exam: value)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                onTap: enabled ? () => _pickTime(context, app) : null,
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
                      profile.reminderTime.format(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                border: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      notifications.supported
                          ? Icons.security_outlined
                          : Icons.phone_android_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notifications.supported
                            ? 'İzin, yalnızca ilk bildirimi açtığında istenir. '
                                  'Görev hatırlatmaları cihazında saklanır.'
                            : 'Bildirimler ilk sürümde yalnızca Android '
                                  'uygulamasında kullanılabilir.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, AppController app) async {
    final time = await showTimePicker(
      context: context,
      initialTime: app.profile.profile.reminderTime,
    );
    if (time != null && context.mounted) {
      await _update(context, app, time: time);
    }
  }

  Future<void> _update(
    BuildContext context,
    AppController app, {
    bool? daily,
    bool? task,
    bool? motivation,
    bool? exam,
    TimeOfDay? time,
  }) async {
    final saved = await app.notifications.updatePreferences(
      daily: daily,
      task: task,
      motivation: motivation,
      exam: exam,
      time: time,
    );
    if (!context.mounted) return;
    AppSnack.show(
      context,
      saved
          ? 'Bildirim tercihi kaydedildi'
          : app.notifications.errorMessage ?? 'Bildirim tercihi kaydedilemedi',
    );
  }
}
