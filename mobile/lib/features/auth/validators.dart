/// Dart port of `features/auth/schemas/auth-schemas.ts`. Plain validator
/// functions returning a message or null, matching `TextFormField.validator`'s
/// contract — same rules and same messages as the Zod schemas, so the two
/// clients reject the same input for the same stated reason.
library;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _tenDigits = RegExp(r'^\d{10}$');
final _hasLetter = RegExp(r'[A-Za-z]');
final _hasNumber = RegExp(r'[0-9]');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

/// `loginSchema.password` only requires non-empty — the strength rules apply
/// when *setting* a password, not when typing an existing one.
String? validateRequiredPassword(String? value) {
  if ((value ?? '').isEmpty) return 'Password is required';
  return null;
}

/// `passwordRule`: 8+ chars, at least one letter, at least one number.
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'At least 8 characters';
  if (!_hasLetter.hasMatch(password)) return 'At least one letter';
  if (!_hasNumber.hasMatch(password)) return 'At least one number';
  return null;
}

String? validateName(String? value) {
  if ((value?.trim() ?? '').length < 2) return 'Name is too short';
  return null;
}

String? validatePhone(String? value) {
  if (!_tenDigits.hasMatch(value?.trim() ?? '')) {
    return 'Enter a 10-digit phone number';
  }
  return null;
}

/// Cross-field rule — `resetPasswordSchema`'s `.refine()`.
String? validateConfirmPassword(String? value, String password) {
  if (value != password) return 'Passwords do not match';
  return null;
}

/// Cross-field rule — `registerBaseSchema`'s `.refine()`: the two company
/// fields are optional at the type level and required only for aggregators.
String? validateAggregatorField(String? value, {required bool isAggregator}) {
  if (!isAggregator) return null;
  if ((value?.trim() ?? '').isEmpty) {
    return 'Company name and contact person are required';
  }
  return null;
}

/// 0-4 score from length + character-class checks, port of
/// `password-strength-meter.tsx`'s `scorePassword`. A UX nudge, not a real
/// entropy calculation.
int scorePassword(String password) {
  if (password.isEmpty) return 0;
  final checks = <bool>[
    password.length >= 8,
    password.length >= 12,
    RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password),
    _hasNumber.hasMatch(password),
    RegExp(r'[^A-Za-z0-9]').hasMatch(password),
  ];
  final passed = checks.where((c) => c).length;
  return passed > 4 ? 4 : passed;
}
