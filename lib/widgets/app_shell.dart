import 'package:flutter/material.dart';

import '../screens/analysis_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/program_screen.dart';
import '../state/auth_session.dart';
import '../state/app_controller.dart';
import 'common.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.profile.profile;
    final auth = AuthScope.maybeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    const screens = [
      DashboardScreen(),
      FocusScreen(),
      AnalysisScreen(),
      ProgramScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              InkWell(
                onTap: () => _openFromDrawer(context, const ProfileScreen()),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage('assets/images/avatar.png'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.userName.isEmpty
                                  ? 'Öğrenci'
                                  : profile.userName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              [profile.studyField, profile.grade]
                                  .where((value) => value.isNotEmpty)
                                  .join(' · '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profilim'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFromDrawer(context, const ProfileScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Hedeflerim'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFromDrawer(context, const GoalsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Bildirimler'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _openFromDrawer(context, const NotificationsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('YKS Asistanı'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFromDrawer(context, const AssistantScreen()),
              ),
              SwitchListTile(
                secondary: Icon(
                  dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                ),
                title: const Text('Koyu tema'),
                value: dark,
                onChanged: app.toggleTheme,
              ),
              if (auth != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Hesap'),
                  subtitle: Text(auth.user?.email ?? 'Google hesabı'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Çıkış yap'),
                  onTap: auth.busy ? null : auth.signOut,
                ),
              ],
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Uygulama hakkında'),
                subtitle: const Text('Zihin Rehberi · v1.0.0'),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Zihin Rehberi'),
        actions: [
          IconButton(
            tooltip: 'YKS Asistanını aç',
            onPressed: () => _open(context, const AssistantScreen()),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Hero(
              tag: 'profile-avatar',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(context, const ProfileScreen()),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/avatar.png'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SizedBox.expand(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                fit: StackFit.expand,
                children: [...previousChildren, ?currentChild],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(.025, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(app.tabIndex),
                child: screens[app.tabIndex],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: NavigationBarTheme(
            data: Theme.of(context).navigationBarTheme.copyWith(
              indicatorColor: app.tabIndex == 0
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.primaryContainer,
            ),
            child: NavigationBar(
              selectedIndex: app.tabIndex,
              onDestinationSelected: app.setTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Panel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Odak',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'Analiz',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Program',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(AppPageRoute(builder: (_) => screen));
  }

  void _openFromDrawer(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (context.mounted) _open(context, screen);
    });
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Zihin Rehberi',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.psychology_outlined, size: 42),
      children: const [
        Text(
          'YKS hazırlık sürecini planlamak, odaklanmak ve gelişimi izlemek için tasarlandı.',
        ),
      ],
    );
  }
}
