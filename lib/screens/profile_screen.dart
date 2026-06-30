import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_controller.dart';
import '../state/auth_session.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  late String _name;
  late String _grade;
  late String _field;
  late String _university;
  late String _department;
  late String _rank;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = AppScope.of(context).profile.profile;
    _name = profile.userName;
    _grade = profile.grade.isEmpty ? '12. Sınıf' : profile.grade;
    _field = profile.studyField.isEmpty ? 'Sayısal' : profile.studyField;
    _university = profile.targetUniversity;
    _department = profile.targetDepartment;
    _rank = profile.targetRank == 0 ? '' : profile.targetRank.toString();
    _initialized = true;
  }

  Future<void> _confirmAccountDeletion(AuthSession auth) async {
    var confirmation = '';
    var password = '';
    final requiresPassword = auth.deletionRequiresPassword;
    final approved = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          final canDelete =
              confirmation.trim().toUpperCase() == 'SİL' &&
              (!requiresPassword || password.isNotEmpty);
          return AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 36,
            ),
            title: const Text('Hesabı ve tüm verileri sil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profilin, görevlerin, denemelerin, odak kayıtların, '
                    'sohbetlerin ve cihaz bildirim tokenların kalıcı olarak '
                    'silinecek. Bu işlem geri alınamaz.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Onaylamak için SİL yaz',
                      prefixIcon: Icon(Icons.delete_forever_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) =>
                        setLocalState(() => confirmation = value),
                  ),
                  if (requiresPassword) ...[
                    const SizedBox(height: 12),
                    TextField(
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Mevcut şifren',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onChanged: (value) =>
                          setLocalState(() => password = value),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Devam ettiğinde Google hesabınla yeniden doğrulama '
                      'istenir.',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: canDelete
                    ? () => Navigator.pop(dialogContext, password)
                    : null,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Kalıcı olarak sil'),
              ),
            ],
          );
        },
      ),
    );
    if (approved == null || !mounted) return;
    final deleted = await auth.deleteAccount(
      password: requiresPassword ? approved : null,
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      AppSnack.show(
        context,
        auth.errorMessage ?? 'Hesap ve veriler silinemedi. Tekrar dene.',
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).profile.updateProfile(
        name: _name.trim(),
        grade: _grade,
        studyField: _field,
        university: _university.trim(),
        department: _department.trim(),
        rank: int.parse(_rank),
      );
      if (mounted) AppSnack.show(context, 'Profil bilgileri güncellendi');
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          'Profil bilgileri kaydedilemedi. Bağlantını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = AppScope.of(context).profile;
    final auth = AuthScope.maybeOf(context);
    final profile = profileController.profile;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                AnimatedEntrance(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primaryContainer,
                          ),
                          child: const CircleAvatar(
                            radius: 48,
                            backgroundImage: AssetImage(
                              'assets/images/avatar.png',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.userName.isEmpty ? 'Öğrenci' : profile.userName,
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
                const SizedBox(height: 24),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Öğrenci bilgileri'),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(
                          labelText: 'Ad soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().length < 3
                            ? 'Ad soyad gerekli'
                            : null,
                        onChanged: (value) => _name = value,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _grade,
                        decoration: const InputDecoration(
                          labelText: 'Sınıf',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items:
                            const [
                                  '9. Sınıf',
                                  '10. Sınıf',
                                  '11. Sınıf',
                                  '12. Sınıf',
                                  'Mezun',
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _grade = value!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _field,
                        decoration: const InputDecoration(
                          labelText: 'Alan',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const ['Sayısal', 'Eşit Ağırlık', 'Sözel', 'Dil']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _field = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('YKS hedefi'),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _university,
                        decoration: const InputDecoration(
                          labelText: 'Hedef üniversite',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        onChanged: (value) => _university = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _department,
                        decoration: const InputDecoration(
                          labelText: 'Hedef bölüm',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        onChanged: (value) => _department = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _rank,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Hedef sıralama',
                          prefixIcon: Icon(Icons.emoji_events_outlined),
                        ),
                        validator: (value) {
                          final rank = int.tryParse(value ?? '');
                          return rank == null || rank < 1
                              ? 'Geçerli bir sıralama gir'
                              : null;
                        },
                        onChanged: (value) => _rank = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _saving ? 'Kaydediliyor…' : 'Değişiklikleri kaydet',
                  ),
                ),
                if (auth != null) ...[
                  const SizedBox(height: 24),
                  SurfaceCard(
                    border: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesap ve veriler',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: scheme.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hesabını ve bu hesaba bağlı bütün çalışma '
                          'verilerini kalıcı olarak silebilirsin.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            side: BorderSide(color: scheme.error),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: auth.busy
                              ? null
                              : () => _confirmAccountDeletion(auth),
                          icon: auth.busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_forever_outlined),
                          label: Text(
                            auth.busy ? 'İşlem sürüyor…' : 'Hesabımı sil',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
