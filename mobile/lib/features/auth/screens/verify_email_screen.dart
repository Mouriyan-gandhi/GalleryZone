import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

/// Port of `features/auth/components/verify-email-status.tsx`. Verification
/// fires on open (and again on "Resend"); success counts down and lands on
/// Login on its own.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.token});

  static const path = '/verify-email';
  static const redirectCountdownSeconds = 3;

  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

enum _VerifyState { pending, success, error }

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  _VerifyState _state = _VerifyState.pending;
  int _countdown = VerifyEmailScreen.redirectCountdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    _timer?.cancel();
    setState(() {
      _state = _VerifyState.pending;
      _countdown = VerifyEmailScreen.redirectCountdownSeconds;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmail(token: widget.token);
      if (!mounted) return;
      setState(() => _state = _VerifyState.success);
      _startCountdown();
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _VerifyState.error);
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _countdown - 1;
      setState(() => _countdown = next < 0 ? 0 : next);
      if (next <= 0) {
        timer.cancel();
        context.go(LoginScreen.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      child: switch (_state) {
        _VerifyState.pending => Column(
            children: [
              CircularProgressIndicator(color: theme.colorScheme.tertiary),
              const SizedBox(height: 20),
              const AuthFormHeader(
                title: 'Verifying your email…',
                description: 'This should only take a moment.',
                centered: true,
              ),
            ],
          ),
        _VerifyState.success => AuthResultPanel(
            icon: LucideIcons.checkCircle2,
            title: 'Email verified',
            description: Text('Redirecting you to sign in in ${_countdown}s…'),
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
        _VerifyState.error => AuthResultPanel(
            icon: LucideIcons.mailWarning,
            title: 'This link is invalid or has expired',
            isError: true,
            description: const Text(
              'Verification links only work once. Request a fresh one below.',
            ),
            children: [
              SizedBox(
                width: 240,
                height: 44,
                child: FilledButton(
                  onPressed: _verify,
                  child: const Text('Resend verification email'),
                ),
              ),
              TextButton(
                onPressed: () => context.go(LoginScreen.path),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
      },
    );
  }
}
