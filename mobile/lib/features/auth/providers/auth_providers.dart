import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_session.dart';
import '../../../data/mock/mock_auth_repository.dart';
import '../../../data/models/auth.dart';
import '../../../data/repositories/auth_repository.dart';
import '../role_options.dart';

/// The one place a concrete repository implementation is named. Swapping in
/// a dio-backed `RemoteAuthRepository` later is an override here — no screen
/// imports `MockAuthRepository` directly.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Session role read from secure storage once, before `runApp` — overridden
/// in `main()`. Reading it up front (rather than exposing an async session)
/// is what lets the router redirect synchronously and skips a splash/loading
/// route entirely.
final initialRoleProvider = Provider<Role?>((ref) {
  throw UnimplementedError('initialRoleProvider must be overridden in main()');
});

/// The signed-in role, or null. This IS the session — the web stores the
/// same value in the `gz_session` cookie; here it lives in the OS keystore
/// (see [SecureSession]). One role per account, no switcher.
class SessionNotifier extends Notifier<Role?> {
  @override
  Role? build() => ref.read(initialRoleProvider);

  Future<void> signIn(Role role, {bool rememberMe = true}) async {
    // `rememberMe: false` mirrors the web's session cookie (no max-age):
    // the role isn't persisted, so it's gone on next launch.
    if (rememberMe) {
      await SecureSession.setRole(role.id);
    } else {
      await SecureSession.clear();
    }
    state = role;
  }

  Future<void> signOut() async {
    await SecureSession.clear();
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Role?>(
  SessionNotifier.new,
);

/// Mock repositories throw `Exception('message')` — strip Dart's
/// `Exception: ` prefix so screens show the message the service wrote, not
/// the wrapper's `toString()`. Kept next to the repository provider because
/// it's a property of how these repositories report failure, and every Auth
/// screen needs it.
String authErrorMessage(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : 'Something went wrong.';
}
