/// Mirrors `services/authService.ts` + `features/auth/schemas/auth-schemas.ts`.
/// Plain classes, not freezed — these are transient form inputs, not data
/// that needs `copyWith`/persistence, and there are five of them here vs.
/// the domain models elsewhere, not worth the codegen for this shape.
enum Role { artist, aggregator, customer }

class LoginInput {
  const LoginInput({required this.email, required this.password, this.rememberMe = false});

  final String email;
  final String password;
  final bool rememberMe;
}

class RegisterInput {
  const RegisterInput({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.acceptedTerms,
    this.companyName,
    this.contactPerson,
  });

  final Role role;
  final String name;
  final String email;
  final String phone;
  final String password;
  final bool acceptedTerms;
  final String? companyName; // required only when role == aggregator
  final String? contactPerson; // required only when role == aggregator
}

class ForgotPasswordInput {
  const ForgotPasswordInput({required this.email});
  final String email;
}

class ResetPasswordInput {
  const ResetPasswordInput({required this.password, required this.confirmPassword, this.token});
  final String password;
  final String confirmPassword;
  final String? token;
}

/// `login`/`register`/`forgotPassword` all resolve this on success.
class AuthAck {
  const AuthAck({required this.email});
  final String email;
}

/// `resetPassword`/`verifyEmail` resolve this on success.
class AuthResult {
  const AuthResult({this.success = true});
  final bool success;
}
