import 'auth.dart';

/// The signed-in account as the server knows it (`GET /v1/auth/me`). The role
/// here — read from the server's own record, never from the sign-in form or a
/// token claim — is what decides which portal opens.
class CurrentUser {
  const CurrentUser({
    required this.uid,
    required this.roleId,
    required this.status,
    required this.name,
    required this.email,
    this.phone,
    this.roleGrants = const [],
  });

  final String uid;

  /// `artist`, `aggregator`, `customer` or `admin` — kept as the raw string
  /// because `admin` is a real role the app deliberately has no portal for.
  final String roleId;

  /// `pending`, `active`, `suspended` or `blocked`.
  final String status;
  final String name;
  final String email;
  final String? phone;
  final List<String> roleGrants;

  /// The portal role, or null for an account the app has no portal for
  /// (admin). See [isAdmin].
  Role? get role {
    for (final candidate in Role.values) {
      if (candidate.name == roleId) return candidate;
    }
    return null;
  }

  bool get isAdmin => roleId == 'admin';
}
