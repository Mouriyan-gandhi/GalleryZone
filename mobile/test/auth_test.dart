import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/router/app_router.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/data/repositories/auth_repository.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/auth/screens/login_screen.dart';
import 'package:gallery_zone/features/auth/validators.dart';

/// No delay and no thrown errors — the widget test asserts on the form's own
/// behavior, not on `mockDelay`'s timing.
class _FakeAuthRepository implements AuthRepository {
  final calls = <LoginInput>[];

  @override
  Future<AuthAck> login(LoginInput input, {bool simulateError = false}) async {
    calls.add(input);
    return AuthAck(email: input.email);
  }

  @override
  Future<AuthAck> register(RegisterInput input, {bool simulateError = false}) async =>
      AuthAck(email: input.email);

  @override
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false}) async =>
      AuthAck(email: input.email);

  @override
  Future<AuthResult> resetPassword(ResetPasswordInput input, {bool simulateError = false}) async =>
      const AuthResult();

  @override
  Future<AuthResult> verifyEmail({String? token, bool simulateError = false}) async =>
      const AuthResult();
}

void main() {
  group('validators mirror the Zod schemas', () {
    test('email', () {
      expect(validateEmail('you@example.com'), isNull);
      expect(validateEmail('nope'), isNotNull);
      expect(validateEmail(''), isNotNull);
    });

    test('new password needs 8 chars, a letter and a number', () {
      expect(validateNewPassword('passw0rd'), isNull);
      expect(validateNewPassword('pass0'), 'At least 8 characters');
      expect(validateNewPassword('12345678'), 'At least one letter');
      expect(validateNewPassword('password'), 'At least one number');
    });

    test('phone is exactly 10 digits', () {
      expect(validatePhone('9876543210'), isNull);
      expect(validatePhone('98765 43210'), isNotNull);
      expect(validatePhone('987654321'), isNotNull);
    });

    test('company fields are required only for aggregators', () {
      expect(validateAggregatorField('', isAggregator: false), isNull);
      expect(validateAggregatorField('', isAggregator: true), isNotNull);
      expect(validateAggregatorField('Northline', isAggregator: true), isNull);
    });

    test('confirm password must match', () {
      expect(validateConfirmPassword('a', 'a'), isNull);
      expect(validateConfirmPassword('a', 'b'), 'Passwords do not match');
    });

    test('password strength climbs 0-4', () {
      expect(scorePassword(''), 0);
      expect(scorePassword('abcdefgh'), 1);
      expect(scorePassword('Abcdefgh1!'), 4);
    });
  });

  group('route guard mirrors proxy.ts', () {
    test('unguarded routes pass through', () {
      expect(redirectFor(null, '/login'), isNull);
      expect(redirectFor(Role.artist, '/register'), isNull);
    });

    test('no session bounces to login carrying ?next', () {
      expect(redirectFor(null, '/dashboard'), '/login?next=%2Fdashboard');
    });

    test('right role for the section passes', () {
      expect(redirectFor(Role.artist, '/dashboard'), isNull);
      expect(redirectFor(Role.aggregator, '/aggregator/dashboard'), isNull);
      expect(redirectFor(Role.customer, '/account'), isNull);
    });

    test('wrong role bounces to its own home, not a blank guard', () {
      expect(redirectFor(Role.customer, '/dashboard'), '/account');
      expect(redirectFor(Role.artist, '/account'), '/dashboard');
      expect(redirectFor(Role.artist, '/aggregator/orders'), '/dashboard');
    });
  });

  testWidgets('login rejects a bad email before calling the repository',
      (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialRoleProvider.overrideWithValue(null),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'passw0rd');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });
}
