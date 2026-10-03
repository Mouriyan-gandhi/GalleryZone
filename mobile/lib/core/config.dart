/// Where the app talks to, and the public identifiers it needs to do so.
///
/// Everything here is public by design — the Firebase *web* API key
/// identifies the project, it authorises nothing (access is decided by
/// Firebase Auth plus the API's role guard), exactly as the website ships it
/// in every page. Each value can still be overridden per build:
///
///   flutter run --dart-define=GZ_API_URL=http://10.0.2.2:8080
///
/// `GZ_MOCK=true` keeps the old offline mock backend — for demos and for
/// working without a network. A release build never sets it.
class AppConfig {
  AppConfig._();

  /// NestJS API, no trailing slash. Production is the only deployed one.
  static const apiBaseUrl = String.fromEnvironment(
    'GZ_API_URL',
    defaultValue: 'https://api-production-9fd9.up.railway.app',
  );

  /// Firebase project `galleryzone-prod` — the web API key, used for the
  /// Identity Toolkit REST calls that sign people in.
  static const firebaseApiKey = String.fromEnvironment(
    'GZ_FIREBASE_API_KEY',
    defaultValue: 'AIzaSyA1TFRbOq-0j-C7uXuz-u6OkirM1CPHxf4',
  );

  /// Canonical public origin. Verification links and QR codes are built from
  /// this, never from where the app happens to be running, so a code printed
  /// from a dev build still points at the real site.
  static const siteUrl = String.fromEnvironment(
    'GZ_SITE_URL',
    defaultValue: 'https://www.galleryzone.art',
  );

  /// Offline mock backend instead of the real API.
  static const useMockBackend = bool.fromEnvironment('GZ_MOCK');
}
