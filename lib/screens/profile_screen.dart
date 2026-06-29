import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
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

  @override
  Widget build(BuildContext context) {
    final profileController = AppScope.of(context).profile;
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
                        [profile.studyField, profile.grade]
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
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
                        decoration: const InputDecoration(
                          labelText: 'Hedef sıralama',
                          prefixIcon: Icon(Icons.emoji_events_outlined),
                        ),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? 'Geçerli bir sayı gir'
                            : null,
                        onChanged: (value) => _rank = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    profileController.updateProfile(
                      name: _name.trim(),
                      grade: _grade,
                      studyField: _field,
                      university: _university.trim(),
                      department: _department.trim(),
                      rank: int.parse(_rank),
                    );
                    AppSnack.show(context, 'Profil bilgileri güncellendi');
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Değişiklikleri kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
