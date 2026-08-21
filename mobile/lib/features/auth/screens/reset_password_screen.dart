import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/auth.dart';
import '../providers/auth_providers.dart';
import '../validators.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

/// Port of `features/auth/components/reset-password-form.tsx`. The token
/// arrives as a query parameter (`?token=…`), same as the emailed web link.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  static const path = '/reset-password';

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;
  bool _isDone = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            ResetPasswordInput(
              password: _password.text,
              confirmPassword: _confirmPassword.text,
              token: widget.token,
            ),
          );
      if (!mounted) return;
      setState(() => _isDone = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) {
      return AuthScaffold(
        child: AuthResultPanel(
          icon: LucideIcons.checkCircle2,
          title: 'Password reset',
          description: const Text(
            'Your password has been updated. Sign in with your new password.',
          ),
          children: [
            SizedBox(
              width: 220,
              height: 44,
              child: FilledButton(
                onPressed: () => context.go(LoginScreen.path),
                child: const Text('Continue to Login'),
              ),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFormHeader(
            title: 'Set a new password',
            description: "Choose a strong password you haven't used before.",
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'New password',
                  controller: _password,
                  validator: validateNewPassword,
                  hint: 'At least 8 characters',
                  icon: LucideIcons.lock,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                PasswordStrengthMeter(password: _password.text),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Confirm new password',
                  controller: _confirmPassword,
                  validator: (value) => validateConfirmPassword(value, _password.text),
                  icon: LucideIcons.lock,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 20),
                AuthSubmitButton(
                  label: 'Reset password',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
