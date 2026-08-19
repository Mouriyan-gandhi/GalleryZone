import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mobile equivalent of the web's `gz_session` cookie — same idea (the
/// stored value IS the role string: `artist`/`aggregator`/`customer`, no
/// separate session id, no real JWT yet since the backend is mocked), but
/// OS-Keychain/Keystore-backed instead of a plain cookie, per SAD §4.1's
/// real requirement for mobile token storage. Not `shared_preferences`
/// (that's for the mock-data collections only, in `mock_db.dart`) — this
/// one value is treated as sensitive from day one so swapping in a real
/// JWT later doesn't move it to a different storage layer.
class SecureSession {
  SecureSession._();

  static const _storage = FlutterSecureStorage();
  static const _roleKey = 'gz_session_role';

  static Future<void> setRole(String role) => _storage.write(key: _roleKey, value: role);

  static Future<String?> getRole() => _storage.read(key: _roleKey);

  static Future<void> clear() => _storage.delete(key: _roleKey);
}
