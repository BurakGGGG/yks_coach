import 'dart:async';

import 'package:flutter/material.dart';

import '../state/auth_session.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AnimatedEntrance(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology_alt_rounded,
                        size: 38,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Zihin Rehberi',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'YKS hazırlığını güvenle tek yerde yönet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      border: true,
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Giriş yap'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Hesap oluştur'),
                                ),
                              ],
                              selected: {_register},
                              showSelectedIcon: false,
                              onSelectionChanged: session.busy
                                  ? null
                                  : (value) =>
                                        _changeMode(value.first, session),
                            ),
                            const SizedBox(height: 20),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              child: _register
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: _name,
                                          enabled: !session.busy,
                                          textInputAction: TextInputAction.next,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Ad soyad',
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                          validator: (value) =>
                                              (value ?? '').trim().length < 3
                                              ? 'Ad soyad en az 3 karakter olmalı'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            TextFormField(
                              controller: _email,
                              enabled: !session.busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              enabled: !session.busy,
                              obscureText: _obscurePassword,
                              textInputAction: _register
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: [
                                _register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onFieldSubmitted: _register
                                  ? null
                                  : (_) => _submit(session),
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Şifreyi göster'
                                      : 'Şifreyi gizle',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => _validatePassword(
                                value ?? '',
                                strict: _register,
                              ),
                            ),
                            if (_register) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmation,
                                enabled: !session.busy,
                                obscureText: _obscureConfirmation,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) => _submit(session),
                                decoration: InputDecoration(
                                  labelText: 'Şifreyi doğrula',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_outlined,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirmation
                                        ? 'Şifreyi göster'
                                        : 'Şifreyi gizle',
                                    onPressed: () => setState(
                                      () => _obscureConfirmation =
                                          !_obscureConfirmation,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmation
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) => value != _password.text
                                    ? 'Şifreler eşleşmiyor'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'En az 10 karakter; büyük harf, küçük harf ve rakam içermeli.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ] else ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: session.busy
                                      ? null
                                      : () => _showResetDialog(session),
                                  child: const Text('Şifremi unuttum'),
                                ),
                              ),
                            ],
                            if (session.errorMessage != null) ...[
                              _ErrorBanner(message: session.errorMessage!),
                              const SizedBox(height: 12),
                            ],
                            FilledButton(
                              onPressed: session.busy
                                  ? null
                                  : () => _submit(session),
                              child: session.busy
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _register
                                          ? 'Hesabımı oluştur'
                                          : 'Giriş yap',
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'veya',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 52),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: session.busy
                                  ? null
                                  : session.signInWithGoogle,
                              icon: const Icon(Icons.account_circle_outlined),
                              label: const Text('Google ile devam et'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Verilerin yalnızca doğrulanmış hesabınla erişilebilir.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeMode(bool register, AuthSession session) {
    setState(() {
      _register = register;
      _confirmation.clear();
    });
    session.clearError();
    _formKey.currentState?.reset();
  }

  Future<void> _submit(AuthSession session) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_register) {
      await session.registerWithEmail(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      await session.signInWithEmail(_email.text, _password.text);
    }
  }

  Future<void> _showResetDialog(AuthSession session) async {
    final controller = TextEditingController(text: _email.text.trim());
    final key = GlobalKey<FormState>();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifreyi sıfırla'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(key.currentState?.validate() ?? false)) return;
              final success = await session.sendPasswordReset(controller.text);
              if (context.mounted) Navigator.pop(context, success);
            },
            child: const Text('Bağlantı gönder'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (sent == true && mounted) {
      AppSnack.show(
        context,
        'Hesap varsa şifre sıfırlama bağlantısı gönderildi.',
      );
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return valid ? null : 'Geçerli bir e-posta adresi gir';
  }

  String? _validatePassword(String value, {required bool strict}) {
    if (!strict) return value.isEmpty ? 'Şifreni gir' : null;
    if (value.length < 10 ||
        !RegExp('[a-z]').hasMatch(value) ||
        !RegExp('[A-Z]').hasMatch(value) ||
        !RegExp('[0-9]').hasMatch(value)) {
      return 'Şifre güvenlik koşullarını karşılamıyor';
    }
    return null;
  }
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SurfaceCard(
                border: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 34,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'E-postanı doğrula',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${session.user?.email ?? 'E-posta adresin'} adresine bir doğrulama bağlantısı gönderdik. Bağlantıya dokunduktan sonra aşağıdan kontrol et.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'E-posta görünmüyorsa spam klasörünü kontrol et.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    if (session.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: session.errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: session.busy
                            ? null
                            : session.checkEmailVerification,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Doğrulamayı kontrol et'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: session.busy || _remaining > 0
                          ? null
                          : () => _resend(session),
                      child: Text(
                        _remaining > 0
                            ? 'Tekrar gönder ($_remaining sn)'
                            : 'E-postayı tekrar gönder',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: session.busy ? null : session.signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Farklı hesapla giriş yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resend(AuthSession session) async {
    final sent = await session.resendVerificationEmail();
    if (!sent || !mounted) return;
    setState(() => _remaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remaining <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
    AppSnack.show(context, 'Doğrulama e-postası tekrar gönderildi.');
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_alt_rounded, size: 58),
          SizedBox(height: 20),
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Hesabın hazırlanıyor...'),
        ],
      ),
    ),
  );
}

class AuthFailureScreen extends StatelessWidget {
  const AuthFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SurfaceCard(
              border: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Bağlantı kurulamadı',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.errorMessage ?? 'Firebase bağlantısını kontrol et.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: session.busy ? null : session.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
