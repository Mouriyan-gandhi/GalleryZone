import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/firebase_rest_auth.dart';
import '../../../core/auth/token_manager.dart';
import '../../../core/config.dart';
import '../../../core/storage/secure_session.dart';
import '../../../data/mock/mock_auth_repository.dart';
import '../../../data/models/account.dart';
import '../../../data/models/auth.dart';
import '../../../data/repositories/auth_repository.dart';
import '../role_options.dart';

/// True when the app is talking to the real API; false for the offline mock.
///
/// Defaults to false so every test (and `--dart-define=GZ_MOCK=true`) runs on
/// fixtures. `main()` flips it with the rest of the remote wiring (see
/// `core/backend.dart`). Screens branch on it only for things that exist in
/// one world and not the other: the mock's "sign in as" choice, its demo
/// payment sheet, its order-advance control.
final remoteBackendProvider = Provider<bool>((ref) => false);

/// The signed-in Firebase identity's tokens. Overridden in `main()` once the
/// stored refresh token has been read; never touched in mock mode.
final tokenManagerProvider = Provider<TokenManager>((ref) {
  throw UnimplementedError('tokenManagerProvider must be overridden in main()');
});

final firebaseAuthProvider = Provider<FirebaseRestAuth>((ref) {
  return FirebaseRestAuth(apiKey: AppConfig.firebaseApiKey);
});

/// The one HTTP client every remote repository shares. When a request that
/// carried a credential is refused even after a token refresh, the session
/// is over: sign out and let the router send the person to sign in again.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenManagerProvider);
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    idToken: tokens.idToken,
    onSessionExpired: () => ref.read(sessionProvider.notifier).expire(),
  );
});

/// The one place a concrete repository implementation is named. `main()`
/// overrides it with `RemoteAuthRepository`; nothing else imports a
/// concrete class.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Session role read from secure storage once, before `runApp` — overridden
/// in `main()`. Reading it up front (rather than exposing an async session)
/// is what lets the router redirect synchronously.
final initialRoleProvider = Provider<Role?>((ref) {
  throw UnimplementedError('initialRoleProvider must be overridden in main()');
});

/// The signed-in role, or null. This is what the router guards on.
///
/// With the real backend the role is whatever the server's own record of the
/// account says (see `RemoteAuthRepository`); it is cached here, and in the
/// OS keystore, so the router can decide the first route synchronously on the
/// next launch. [accountProvider] then checks it against the server in the
/// background.
class SessionNotifier extends Notifier<Role?> {
  @override
  Role? build() => ref.read(initialRoleProvider);

  Future<void> signIn(Role role, {bool rememberMe = true}) async {
    // `rememberMe: false` mirrors the website's session cookie (no max-age):
    // the role isn't persisted, so it's gone on next launch.
    if (rememberMe) {
      await SecureSession.setRole(role.id);
    } else {
      await SecureSession.clear();
    }
    ref.read(sessionEndedProvider.notifier).clear();
    state = role;
  }

  /// Ends the session everywhere: the server-side tokens, the stored role,
  /// and the cached account. Safe to call twice.
  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Forgetting local tokens cannot meaningfully fail; carry on regardless.
    }
    await SecureSession.clear();
    state = null;
  }

  /// Makes the role cached on this device agree with what the server says
  /// about the account: a different role is adopted, and a session the server
  /// no longer recognises (or an account the app has no portal for - an
  /// admin) is ended. [user] null means the server did not recognise it.
  void reconcile(CurrentUser? user) {
    final current = state;
    if (current == null) return;
    final role = user?.role;
    if (role == null) {
      expire();
    } else if (role != current) {
      signIn(role);
    }
  }

  /// The server stopped accepting this session (or the account was closed).
  /// Sign out and leave a note for the sign-in screen to show once.
  void expire() {
    if (state == null) return;
    ref.read(sessionEndedProvider.notifier).mark();
    signOut();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Role?>(SessionNotifier.new);

/// Set when a session ended on its own (not because the person signed out),
/// so the sign-in screen can say why they are back there.
class SessionEndedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final sessionEndedProvider = NotifierProvider<SessionEndedNotifier, bool>(SessionEndedNotifier.new);

/// Who the server says is signed in — name, email, role, status. It watches
/// the session, so it is read again whenever the role changes or the person
/// signs out; a sign-in screen invalidates it explicitly too, for the case of
/// switching to a different account of the *same* role. Null in mock
/// mode (which has no account record), when signed out, or once the session
/// has ended. A network error leaves it unresolved rather than signing anyone
/// out: being offline is not a reason to lose a session.
final accountProvider = FutureProvider<CurrentUser?>((ref) async {
  if (ref.watch(sessionProvider) == null) return null;
  return ref.watch(authRepositoryProvider).resumeSession();
});

/// Mock repositories throw `Exception('message')` — strip Dart's
/// `Exception: ` prefix so screens show the message the repository wrote, not
/// the wrapper's `toString()`. The real layer's errors (`ApiError`, Firebase's)
/// are written to read the same way, so every screen shows both alike.
String authErrorMessage(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : 'Something went wrong.';
}
