import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/auth.dart';
import '../providers/auth_providers.dart';
import '../validators.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Port of `features/auth/components/forgot-password-form.tsx`. Two states
/// only — form and sent. There is deliberately no error path: this screen
/// never confirms or denies whether an account exists for an address (real
/// security practice, not a mock-phase shortcut).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const path = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isSubmitting = false;
  bool _isSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(ForgotPasswordInput(email: _email.text.trim()));
      if (!mounted) return;
      setState(() => _isSent = true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isSent) {
      return AuthScaffold(
        child: AuthResultPanel(
          icon: LucideIcons.mailCheck,
          title: 'Check your email',
          description: Text.rich(
            TextSpan(
              text: 'If an account exists for ',
              children: [
                TextSpan(
                  text: _email.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const TextSpan(text: ", we've sent a link to reset your password."),
              ],
            ),
          ),
          children: [
            TextButton.icon(
              onPressed: () => context.go(LoginScreen.path),
              icon: const Icon(LucideIcons.arrowLeft, size: 14),
              label: const Text('Back to sign in'),
            ),
            DevPanel(
              child: Row(
                children: [
                  const Expanded(child: Text('Skip the real email')),
                  TextButton(
                    onPressed: () => context.push('${ResetPasswordScreen.path}?token=mock'),
                    child: const Text('Skip to reset form'),
                  ),
                ],
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
            title: 'Forgot your password?',
            description: "Enter your email and we'll send you a link to reset it.",
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Email',
                  controller: _email,
                  validator: validateEmail,
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 20),
                AuthSubmitButton(
                  label: 'Send reset link',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.go(LoginScreen.path),
            icon: const Icon(LucideIcons.arrowLeft, size: 14),
            label: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
