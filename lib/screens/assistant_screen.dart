import 'package:flutter/material.dart';

import '../state/app_state.dart';
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

  Future<void> _send(AppState state, [String? prompt]) async {
    if (state.assistantTyping) {
      AppSnack.show(context, 'Asistan yanıtını hazırlıyor');
      return;
    }
    final message = prompt ?? _controller.text;
    if (message.trim().isEmpty) {
      AppSnack.show(context, 'Asistana göndermek için bir mesaj yaz');
      return;
    }
    _controller.clear();
    final future = state.sendCoachMessage(message);
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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              SizedBox(
                height: 46,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ActionChip(
                      label: const Text('Bugünkü programım'),
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      onPressed: state.assistantTyping
                          ? null
                          : () => _send(state, 'Bugünkü programımı düzenle'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Netlerimi yorumla'),
                      avatar: const Icon(Icons.analytics_outlined, size: 18),
                      onPressed: state.assistantTyping
                          ? null
                          : () => _send(state, 'Deneme netlerimi yorumla'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Motivasyon'),
                      avatar: const Icon(Icons.bolt_outlined, size: 18),
                      onPressed: state.assistantTyping
                          ? null
                          : () => _send(
                              state,
                              'Çalışmak için motivasyona ihtiyacım var',
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount:
                      state.coachMessages.length +
                      (state.assistantTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.coachMessages.length) {
                      return const _TypingBubble();
                    }
                    final message = state.coachMessages[index];
                    return AnimatedEntrance(
                      key: ValueKey(
                        '${message.time.microsecondsSinceEpoch}-$index',
                      ),
                      child: Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 315),
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
                                : Border.all(color: scheme.outlineVariant),
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
                          onSubmitted: (_) => _send(state),
                          decoration: const InputDecoration(
                            hintText: 'Asistana sor...',
                            prefixIcon: Icon(Icons.auto_awesome_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Gönder',
                        onPressed: state.assistantTyping
                            ? null
                            : () => _send(state),
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
