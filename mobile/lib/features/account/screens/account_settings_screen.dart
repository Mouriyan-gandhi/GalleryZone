import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../data/models/customer.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/validators.dart';
import '../providers/account_providers.dart';
import '../widgets/delete_account.dart';

/// Port of `app/account/settings/page.tsx`. Deliberately small: name, email
/// and phone only. No password change (there is no real auth session to
/// change one against yet) and no notification toggles — nothing here
/// controls a system that doesn't exist.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  static const path = '/account/settings';

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _isSaving = false;
  bool _isSeeded = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(customerRepositoryProvider).updateProfile(
            CustomerProfile(
              name: _name.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
            ),
          );
      ref.invalidate(customerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(customerProfileProvider);

    // Fill the fields once, from the first successful load — later rebuilds
    // must not clobber what the user is typing.
    final loaded = profile.value;
    if (!_isSeeded && loaded != null) {
      _isSeeded = true;
      _name.text = loaded.name;
      _email.text = loaded.email;
      _phone.text = loaded.phone;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.isLoading && !_isSeeded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  maxWidth: 560,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              initials(loaded?.name ?? ''),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: theme.colorScheme.tertiary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          validator: validateName,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(labelText: 'Full name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          validator: validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          // Looser than registration's strict 10 digits: the
                          // seeded profile carries a +91 country code, and
                          // rejecting the app's own fixture would be absurd.
                          validator: (value) => (value ?? '').trim().length < 10
                              ? 'Enter a valid phone number'
                              : null,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _save,
                            child: Text(_isSaving ? 'Saving…' : 'Save changes'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(sessionProvider.notifier).signOut();
                            if (context.mounted) context.go(LoginScreen.path);
                          },
                          icon: const Icon(LucideIcons.logOut, size: 16),
                          label: const Text('Sign out'),
                        ),
                        const Divider(height: 32),
                        const DeleteAccountTile(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
