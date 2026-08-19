import '../models/auth.dart';
import '../repositories/auth_repository.dart';
import 'mock_utils.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthAck> login(LoginInput input, {bool simulateError = false}) {
    if (simulateError) return mockError('Invalid email or password.');
    return mockDelay(() => AuthAck(email: input.email));
  }

  @override
  Future<AuthAck> register(RegisterInput input, {bool simulateError = false}) {
    if (simulateError) return mockError('An account with this email already exists.');
    return mockDelay(() => AuthAck(email: input.email));
  }

  @override
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false}) {
    if (simulateError) return mockError('Could not send reset email.');
    return mockDelay(() => AuthAck(email: input.email));
  }

  @override
  Future<AuthResult> resetPassword(ResetPasswordInput input, {bool simulateError = false}) {
    if (simulateError) return mockError('Reset link is invalid or expired.');
    return mockDelay(() => const AuthResult());
  }

  @override
  Future<AuthResult> verifyEmail({String? token, bool simulateError = false}) {
    // Failure is driven by the token value itself, same as the web mock
    // (mirrors how a real bad/expired link would arrive as a URL param),
    // plus a longer delay so the "Verifying…" state reads as real work.
    if (simulateError || token == 'invalid') return mockError('This verification link is invalid or has expired.');
    return mockDelay(() => const AuthResult(), duration: const Duration(milliseconds: 1200));
  }
}
