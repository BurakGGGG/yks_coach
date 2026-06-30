import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/coach_controller.dart';
import '../widgets/common.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(CoachController coach, [String? prompt]) async {
    if (coach.typing) {
      AppSnack.show(context, 'Asistan yanıtını hazırlıyor');
      return;
    }
    final message = prompt ?? _controller.text;
    if (message.trim().isEmpty) {
      AppSnack.show(context, 'Asistana göndermek için bir mesaj yaz');
      return;
    }
    _controller.clear();
    final future = coach.sendMessage(message);
    _scrollToBottom();
    await future;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _confirmClear(
    BuildContext context,
    CoachController coach,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbet geçmişini temizle'),
        content: const Text(
          'Tüm asistan sohbet geçmişin silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await coach.clearHistory();
      if (context.mounted) AppSnack.show(context, 'Sohbet geçmişi temizlendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = AppScope.of(context).coach;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('YKS Asistanı'),
            Text(
              'Yerel demo',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          if (coach.messages.isNotEmpty)
            IconButton(
              tooltip: 'Geçmişi temizle',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, coach),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ActionChip(
                      label: const Text('Bugünkü programım'),
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      onPressed: coach.typing
                          ? null
                          : () => _send(coach, 'Bugünkü programımı düzenle'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Netlerimi yorumla'),
                      avatar: const Icon(Icons.analytics_outlined, size: 18),
                      onPressed: coach.typing
                          ? null
                          : () => _send(coach, 'Deneme netlerimi yorumla'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Motivasyon'),
                      avatar: const Icon(Icons.bolt_outlined, size: 18),
                      onPressed: coach.typing
                          ? null
                          : () => _send(
                              coach,
                              'Çalışmak için motivasyona ihtiyacım var',
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: coach.messages.isEmpty && !coach.typing
                    ? _EmptyConversation(scheme: scheme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount:
                            coach.messages.length + (coach.typing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == coach.messages.length) {
                            return const _TypingBubble();
                          }
                          final message = coach.messages[index];
                          return AnimatedEntrance(
                            key: ValueKey(
                              '${message.createdAt.microsecondsSinceEpoch}-$index',
                            ),
                            child: Align(
                              alignment: message.fromUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 315,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: message.fromUser
                                      ? scheme.primaryContainer
                                      : scheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(
                                      message.fromUser ? 18 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      message.fromUser ? 4 : 18,
                                    ),
                                  ),
                                  border: message.fromUser
                                      ? null
                                      : Border.all(
                                          color: scheme.outlineVariant,
                                        ),
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: message.fromUser
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurface,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(coach),
                          decoration: const InputDecoration(
                            hintText: 'Asistana sor...',
                            prefixIcon: Icon(Icons.auto_awesome_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Gönder',
                        onPressed: coach.typing ? null : () => _send(coach),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'YKS Asistanına hoş geldin',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Programın, netlerin veya motivasyon için aşağıdan bir soru '
              'seçebilir ya da kendi sorunu yazabilirsin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: reduceMotion
            ? const Icon(Icons.more_horiz, size: 22)
            : FadeTransition(
                opacity: Tween(begin: .35, end: 1.0).animate(_controller),
                child: const Icon(Icons.more_horiz, size: 22),
              ),
      ),
    );
  }
}
