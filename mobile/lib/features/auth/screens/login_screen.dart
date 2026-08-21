import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/auth.dart';
import '../providers/auth_providers.dart';
import '../role_options.dart';
import '../validators.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Port of `features/auth/components/login-form.tsx`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.next});

  static const path = '/login';

  /// Where the guard bounced the user from, carried through as `?next=` the
  /// same way `proxy.ts` does it.
  final String? next;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // The role toggle is the only signal this mock phase has for "which
  // dashboard should a successful login land on" — there's no backend to
  // carry that, so it's the real "sign in as" control, not a hidden dev
  // affordance.
  Role _demoRole = Role.artist;
  bool _rememberMe = false;
  bool _simulateError = false;
  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _formError = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(authRepositoryProvider).login(
            LoginInput(
              email: _email.text.trim(),
              password: _password.text,
              rememberMe: _rememberMe,
            ),
            simulateError: _simulateError,
          );
      await ref
          .read(sessionProvider.notifier)
          .signIn(_demoRole, rememberMe: _rememberMe);
      if (!mounted) return;
      context.go(widget.next ?? _demoRole.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            value: _demoRole,
            onChanged: (role) => setState(() => _demoRole = role),
          ),
          const SizedBox(height: 24),
          const AuthFormHeader(
            title: 'Welcome back',
            description: 'Pick your role above, then sign in to continue.',
            icon: LucideIcons.logIn,
          ),
          if (_formError != null) ...[
            const SizedBox(height: 20),
            AuthErrorBanner(message: _formError!),
          ],
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  label: 'Password',
                  controller: _password,
                  validator: validateRequiredPassword,
                  hint: 'Your password',
                  icon: LucideIcons.lock,
                  obscure: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                            ),
                            const Flexible(child: Text('Remember me')),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(ForgotPasswordScreen.path),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AuthSubmitButton(
                  label: 'Sign in',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                DevPanel(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Simulate invalid credentials')),
                      Switch(
                        value: _simulateError,
                        onChanged: (value) => setState(() => _simulateError = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // The marketplace is public (no session needed), same as the web's
          // header nav — reachable before signing in, not only after.
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/marketplace'),
              icon: const Icon(LucideIcons.compass, size: 16),
              label: const Text('Browse the marketplace'),
            ),
          ),
          const SizedBox(height: 8),
          const SocialAuthRow(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?", style: theme.textTheme.bodySmall),
              TextButton(
                onPressed: () => context.push(RegisterScreen.path),
                child: const Text('Create one'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
