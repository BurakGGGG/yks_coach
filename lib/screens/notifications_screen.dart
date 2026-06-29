import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/profile_controller.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = AppScope.of(context).profile;
    final profile = profileController.profile;
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
                        onChanged: (value) =>
                            profileController.updateNotifications(daily: value),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.task_alt_outlined),
                        title: const Text('Görev başlangıçları'),
                        subtitle: const Text('Görevden 10 dakika önce uyarır.'),
                        value: profile.taskReminder,
                        onChanged: (value) =>
                            profileController.updateNotifications(task: value),
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
                        onChanged: (value) =>
                            profileController.updateNotifications(motivation: value),
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
                        onChanged: (value) =>
                            profileController.updateNotifications(exam: value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                onTap: () => _pickTime(context, profileController),
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

  Future<void> _pickTime(
    BuildContext context,
    ProfileController profileController,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: profileController.profile.reminderTime,
    );
    if (time != null) profileController.updateNotifications(time: time);
  }
}
