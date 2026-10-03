import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_error.dart';
import 'firebase_rest_auth.dart';

/// Where the long-lived refresh token lives between launches.
abstract class RefreshTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// The OS keystore — the same place the session role already sits. The ID
/// token itself is never stored: it lasts an hour and is minted from this.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'gz_refresh_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Holds the signed-in Firebase identity and hands the API client a valid ID
/// token on demand.
///
/// Refreshing is single-flight: several requests that find the token stale at
/// once share one network call instead of each spending the refresh token.
/// A refresh that fails because the *token* is dead ends the session; one that
/// fails because the phone is offline does not — that is reported as a
/// network error and the session survives for the next attempt.
class TokenManager {
  TokenManager({
    required this._auth,
    this._store = const SecureRefreshTokenStore(),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final FirebaseRestAuth _auth;
  final RefreshTokenStore _store;
  final DateTime Function() _now;

  FirebaseSession? _session;
  String? _refreshToken;
  Future<FirebaseSession>? _refreshing;

  /// Reads the saved refresh token. A local read, so it is safe before the
  /// first frame — nothing here touches the network.
  Future<void> load() async => _refreshToken = await _store.read();

  /// Whether a session exists to resume (no claim that it is still valid).
  bool get hasSession => _session != null || _refreshToken != null;

  /// Starts a session from a fresh sign-in. [remember] false keeps it in
  /// memory only, so it ends with the process — the mobile reading of the
  /// website's session cookie when "Keep me signed in" is unticked.
  Future<void> start(FirebaseSession session, {required bool remember}) async {
    _session = session;
    _refreshToken = session.refreshToken;
    if (remember) {
      await _store.write(session.refreshToken);
    } else {
      await _store.clear();
    }
  }

  Future<void> clear() async {
    _session = null;
    _refreshToken = null;
    _refreshing = null;
    await _store.clear();
  }

  /// The ID token for the next request, or `null` when signed out.
  Future<String?> idToken({bool forceRefresh = false}) async {
    final current = _session;
    if (current != null && !forceRefresh && current.isFresh(_now())) return current.idToken;

    final refresh = current?.refreshToken ?? _refreshToken;
    if (refresh == null) return null;

    try {
      final next = await (_refreshing ??= _refresh(refresh));
      return next.idToken;
    } on FirebaseAuthException catch (error) {
      if (error.endsSession) {
        await clear();
        return null;
      }
      throw ApiError(status: 0, code: 'network_error', message: error.message);
    }
  }

  Future<FirebaseSession> _refresh(String refreshToken) async {
    try {
      final next = await _auth.refresh(refreshToken);
      _session = next;
      _refreshToken = next.refreshToken;
      if (next.refreshToken != refreshToken && await _store.read() != null) {
        await _store.write(next.refreshToken);
      }
      return next;
    } finally {
      _refreshing = null;
    }
  }
}
