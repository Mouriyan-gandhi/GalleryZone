import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/auth/firebase_rest_auth.dart';
import '../../core/auth/token_manager.dart';
import '../models/account.dart';
import '../models/auth.dart';
import '../repositories/auth_repository.dart';

/// Sign-in against the real thing: Firebase proves who is calling, the API's
/// own record says what they are.
///
///  * Email + password go to Firebase over its REST endpoints
///    ([FirebaseRestAuth]); the API never sees a password.
///  * The role comes from `GET /v1/auth/me` — the server's record of the
///    account — never from the form. That is also why the "sign in as"
///    choice the offline mock needs is gone.
///  * Registration creates the account and profile through the API
///    (`POST /v1/auth/register`) and then signs in with the same credentials.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({required this.api, required this.firebase, required this.tokens});

  final ApiClient api;
  final FirebaseRestAuth firebase;
  final TokenManager tokens;

  static const _adminMessage =
      'Admin tools are on the GalleryZone website. Sign in at galleryzone.art to use them.';

  Future<CurrentUser> _me() async {
    final json = await api.getMap('/v1/auth/me');
    return CurrentUser(
      uid: json['uid'] as String? ?? '',
      roleId: json['role'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roleGrants: [
        for (final grant in (json['roleGrants'] as List? ?? const []))
          if (grant is String) grant,
      ],
    );
  }

  /// Signs in to Firebase, then asks the API who that is.
  Future<AuthAck> _establish(String email, String password, {required bool remember}) async {
    final session = await firebase.signInWithPassword(email.trim(), password);
    await tokens.start(session, remember: remember);

    final CurrentUser user;
    try {
      user = await _me();
    } on ApiError catch (error) {
      // Signed in to Firebase but there is no GalleryZone profile behind it:
      // nowhere useful to route them.
      await tokens.clear();
      if (error.isUnauthorized) {
        throw Exception('No GalleryZone account exists for this sign-in yet. Create one first.');
      }
      rethrow;
    }

    final role = user.role;
    if (role == null) {
      // An admin: a real account, but not one the app has a portal for.
      await tokens.clear();
      throw Exception(_adminMessage);
    }
    return AuthAck(email: user.email.isEmpty ? email : user.email, role: role, name: user.name);
  }

  @override
  Future<AuthAck> login(LoginInput input, {bool simulateError = false}) =>
      _establish(input.email, input.password, remember: input.rememberMe);

  @override
  Future<AuthAck> register(RegisterInput input, {bool simulateError = false}) async {
    await api.post(
      '/v1/auth/register',
      auth: false,
      body: {
        'email': input.email.trim(),
        'password': input.password,
        'name': input.name.trim(),
        'role': input.role.name,
        'phone': input.phone,
      },
    );
    final ack = await _establish(input.email, input.password, remember: true);

    // The sign-up form asks an aggregator for its company name, but the
    // account endpoint has nowhere to put it. Saving it on the profile now
    // means they are not asked twice. Best effort: a failure here must not
    // undo a registration that worked.
    final company = input.companyName?.trim() ?? '';
    if (input.role == Role.aggregator && company.isNotEmpty) {
      try {
        await api.patch('/v1/me/profile', body: {'companyName': company});
      } on ApiError {
        // They can enter it on their profile.
      }
    }
    return ack;
  }

  /// The API answers 202 whether or not the address has an account, so this
  /// cannot be used to find out who is registered.
  @override
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false}) async {
    await api.post('/v1/auth/password-reset', auth: false, body: {'email': input.email.trim()});
    return AuthAck(email: input.email);
  }

  /// [ResetPasswordInput.token] is Firebase's `oobCode` from the emailed link.
  @override
  Future<AuthResult> resetPassword(ResetPasswordInput input, {bool simulateError = false}) async {
    final code = input.token;
    if (code == null || code.isEmpty) {
      throw Exception('This reset link is missing its code. Request a new one.');
    }
    await firebase.confirmPasswordReset(code, input.password);
    return const AuthResult();
  }

  @override
  Future<AuthResult> verifyEmail({String? token, bool simulateError = false}) async {
    if (token == null || token.isEmpty) {
      throw Exception('This verification link is missing its code.');
    }
    await firebase.applyActionCode(token);
    return const AuthResult();
  }

  @override
  Future<void> signOut() => tokens.clear();

  @override
  Future<void> requestAccountDeletion() async {
    await api.post(
      '/v1/support',
      body: {
        'subject': 'Account deletion request',
        'message':
            'Please close my GalleryZone account and delete my data. Sent from the GalleryZone app. '
            'I understand any wallet balance should be withdrawn first.',
      },
    );
  }

  @override
  Future<CurrentUser?> resumeSession() async {
    if (!tokens.hasSession) return null;
    try {
      return await _me();
    } on ApiError catch (error) {
      // A refused session is over; a missing network is not.
      if (error.isUnauthorized || error.isAccountClosed) {
        await tokens.clear();
        return null;
      }
      rethrow;
    }
  }
}
