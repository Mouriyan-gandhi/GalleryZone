import '../models/account.dart';
import '../models/auth.dart';

/// Mirrors `services/authService.ts` exactly — no JWT (mock phase), fake
/// acks only. `simulateError` on each method is the same dev-only demo
/// toggle the web forms expose, kept for parity. A `Remote`-prefixed
/// dio-backed implementation swaps in behind this interface once SAD §4's
/// real JWT auth exists — screens never see the difference.
abstract class AuthRepository {
  Future<AuthAck> login(LoginInput input, {bool simulateError = false});
  Future<AuthAck> register(RegisterInput input, {bool simulateError = false});
  Future<AuthAck> forgotPassword(ForgotPasswordInput input, {bool simulateError = false});
  Future<AuthResult> resetPassword(ResetPasswordInput input, {bool simulateError = false});
  Future<AuthResult> verifyEmail({String? token, bool simulateError = false});

  /// Ends the session: the real backend forgets the tokens. The offline mock
  /// has nothing to forget.
  Future<void> signOut();

  /// Asks GalleryZone to close this account and remove its data.
  ///
  /// The API has no self-service delete route yet, so with the real backend
  /// this raises a support ticket that the team acts on - and the screen says
  /// so, rather than claiming the account is already gone. The offline mock
  /// has no server side; the screen clears the device's own data.
  Future<void> requestAccountDeletion();

  /// Checks that a stored session is still good and says who it belongs to —
  /// the server's own record of the account, including its role. Null when
  /// there is no session, or it has ended. The offline mock never has one:
  /// its "session" is just the role chosen on the device.
  Future<CurrentUser?> resumeSession();
}
