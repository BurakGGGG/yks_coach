import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pendingScreen = app.takePendingScreen();
    if (pendingScreen == 'assistant') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _open(context, const AssistantScreen());
      });
    }
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
                              [
                                profile.studyField,
                                profile.grade,
                              ].where((value) => value.isNotEmpty).join(' · '),
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
            child: _AnimatedTabBody(index: app.tabIndex, children: screens),
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
              onDestinationSelected: (index) {
                if (index == app.tabIndex) return;
                HapticFeedback.selectionClick();
                app.setTab(index);
              },
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

class _AnimatedTabBody extends StatefulWidget {
  const _AnimatedTabBody({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _currentIndex;
  int? _previousIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller =
        AnimationController(vsync: this, duration: AppMotion.standard, value: 1)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _previousIndex != null) {
              setState(() => _previousIndex = null);
            }
          });
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _currentIndex) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _previousIndex = _currentIndex;
    _direction = widget.index > _currentIndex ? 1 : -1;
    _currentIndex = widget.index;
    if (reduceMotion) {
      _previousIndex = null;
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indices = <int>[
      for (var index = 0; index < widget.children.length; index++)
        if (index != _previousIndex && index != _currentIndex) index,
      ?_previousIndex,
      _currentIndex,
    ];
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final enter = Curves.easeOutCubic.transform(_controller.value);
          final exit = Curves.easeInCubic.transform(_controller.value);
          return Stack(
            fit: StackFit.expand,
            children: indices.map((index) {
              final isCurrent = index == _currentIndex;
              final isPrevious = index == _previousIndex;
              final visible = isCurrent || isPrevious;
              final opacity = isCurrent
                  ? (_previousIndex == null ? 1.0 : enter)
                  : isPrevious
                  ? 1 - exit
                  : 0.0;
              final offset = isCurrent
                  ? Offset(
                      _previousIndex == null
                          ? 0
                          : (1 - enter) * .045 * _direction,
                      0,
                    )
                  : Offset(-exit * .022 * _direction, 0);
              return Positioned.fill(
                key: ValueKey('tab-$index'),
                child: Offstage(
                  offstage: !visible,
                  child: TickerMode(
                    enabled: isCurrent,
                    child: IgnorePointer(
                      ignoring: !isCurrent,
                      child: Opacity(
                        opacity: opacity.clamp(0, 1),
                        child: FractionalTranslation(
                          translation: offset,
                          child: RepaintBoundary(child: widget.children[index]),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
