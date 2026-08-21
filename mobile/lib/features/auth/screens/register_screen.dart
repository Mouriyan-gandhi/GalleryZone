import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/auth.dart';
import '../providers/auth_providers.dart';
import '../role_options.dart';
import '../validators.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

/// Port of `features/auth/components/register-form.tsx`. One form for all
/// three roles (not three forms): the aggregator-only company fields appear
/// and become required when that role is picked, mirroring the single Zod
/// schema with a `.refine()` rather than a discriminated union.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.initialRole});

  static const path = '/register';

  final Role? initialRole;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _companyName = TextEditingController();
  final _contactPerson = TextEditingController();

  late Role _role = widget.initialRole ?? Role.artist;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  bool _isRegistered = false;

  bool get _isAggregator => _role == Role.aggregator;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _companyName, _contactPerson]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    // `acceptedTerms` has no field of its own to attach a validator to (the
    // web enforces it via `z.literal(true)`), so it's checked alongside the
    // form's own validation.
    final formValid = _formKey.currentState!.validate();
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept the Terms')),
      );
    }
    if (!formValid || !_acceptedTerms) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).register(
            RegisterInput(
              role: _role,
              name: _name.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              password: _password.text,
              acceptedTerms: _acceptedTerms,
              companyName: _isAggregator ? _companyName.text.trim() : null,
              contactPerson: _isAggregator ? _contactPerson.text.trim() : null,
            ),
          );
      if (!mounted) return;
      setState(() => _isRegistered = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Same fake-session write login performs — skip the form and drop
  /// straight into that role's (mock-data-driven) home.
  Future<void> _demoSignIn(Role role) async {
    await ref.read(sessionProvider.notifier).signIn(role);
    if (!mounted) return;
    context.go(role.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isRegistered) {
      return AuthScaffold(
        child: AuthResultPanel(
          icon: LucideIcons.mailCheck,
          title: 'Check your email',
          description: Text.rich(
            TextSpan(
              text: "We've sent a verification link to ",
              children: [
                TextSpan(
                  text: _email.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const TextSpan(text: '. Follow it to activate your account.'),
              ],
            ),
          ),
          children: [
            TextButton(
              onPressed: () => context.go(LoginScreen.path),
              child: const Text('Back to sign in'),
            ),
            DevPanel(
              child: Row(
                children: [
                  const Expanded(child: Text('Skip the real email')),
                  TextButton(
                    onPressed: () => context.push('${VerifyEmailScreen.path}?token=mock'),
                    child: const Text('Skip to verification'),
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
          const AuthCrest(),
          const SizedBox(height: 24),
          RoleToggle<Role>(
            options: [
              for (final option in roleOptions)
                (label: option.label, icon: option.icon, value: option.role),
            ],
            value: _role,
            onChanged: (role) => setState(() => _role = role),
          ),
          const SizedBox(height: 24),
          const AuthFormHeader(
            title: 'Create an account',
            description: 'Join GalleryZone and showcase your art.',
            icon: LucideIcons.userPlus,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  label: 'Full name',
                  controller: _name,
                  validator: validateName,
                  hint: 'Ananya Rao',
                  icon: LucideIcons.user,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Email Address',
                  controller: _email,
                  validator: validateEmail,
                  hint: 'you@example.com',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Phone number',
                  controller: _phone,
                  validator: validatePhone,
                  hint: '98765 43210',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                if (_isAggregator) ...[
                  const SizedBox(height: 18),
                  AuthTextField(
                    label: 'Company / gallery name',
                    controller: _companyName,
                    validator: (value) =>
                        validateAggregatorField(value, isAggregator: true),
                    hint: 'Northline Art Space',
                    icon: LucideIcons.building2,
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    label: 'Contact person',
                    controller: _contactPerson,
                    validator: (value) =>
                        validateAggregatorField(value, isAggregator: true),
                    hint: 'Full name',
                    icon: LucideIcons.user,
                  ),
                ],
                const SizedBox(height: 18),
                AuthTextField(
                  label: 'Password',
                  controller: _password,
                  validator: validateNewPassword,
                  hint: 'Min 8 characters, 1 letter, 1 number',
                  icon: LucideIcons.lock,
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                    const Expanded(child: Text('I agree to the Terms of Service')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final option in roleOptions) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _demoSignIn(option.role),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Column(
                            children: [
                              Icon(option.icon, size: 16, color: theme.colorScheme.tertiary),
                              const SizedBox(height: 4),
                              Text(
                                'Demo ${option.label}',
                                style: theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (option != roleOptions.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                AuthSubmitButton(
                  label: 'Create account',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SocialAuthRow(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?', style: theme.textTheme.bodySmall),
              TextButton(
                onPressed: () => context.go(LoginScreen.path),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
