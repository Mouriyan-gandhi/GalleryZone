/// A failed API call, in the one shape the screens deal with.
///
/// The API answers every error as RFC 7807 (`{type,title,status,code,detail}`).
/// [message] is `detail ?? title` — the validation issue list is more useful
/// to a person than the generic title — which is the same rule the website's
/// `ApiError` follows, so the two clients say the same thing for the same
/// failure.
///
/// [status] 0 means no response came back at all (offline, DNS, timeout).
class ApiError implements Exception {
  const ApiError({
    required this.status,
    required this.code,
    required this.message,
    this.title,
  });

  final int status;

  /// Machine-readable reason: `unauthorized`, `forbidden`, `account_suspended`,
  /// `rate_limited`, `network_error`, `conflict`, `not_found` …
  final String code;

  final String message;
  final String? title;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isRateLimited => status == 429;

  /// The account itself is closed to this person (suspended or blocked).
  bool get isAccountClosed => code == 'account_suspended' || code == 'account_blocked';

  /// Reads as `Exception: <message>` on purpose. The mock repositories throw
  /// `Exception('…')` and every screen strips that prefix to show the text;
  /// matching it means a real API failure renders through the same call sites
  /// without each one learning a second error type.
  @override
  String toString() => 'Exception: $message';
}
