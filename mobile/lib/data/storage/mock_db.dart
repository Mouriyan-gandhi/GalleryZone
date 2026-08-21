import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dart port of `frontend-web/lib/mock-db.ts`. Same lazy-seed-on-first-read
/// behavior, same `gz-db-v1:` key prefix, same one-collection-per-domain-
/// object shape (`lib/mock-collections.ts`) — kept identical on purpose so
/// this app's mock data model can be swapped for a real backend the same
/// day the web client's is, behind the same repository interfaces.
class MockDb {
  MockDb._();

  static const _prefix = 'gz-db-v1:';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Drops the cached handle. Without this a test that calls
  /// `SharedPreferences.setMockInitialValues({})` still reads the previous
  /// test's data, because [init] would keep the handle it already had.
  @visibleForTesting
  static void resetForTesting() => _prefs = null;

  static SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('MockDb.init() must be awaited before use (call it in main()).');
    }
    return prefs;
  }

  /// Reads collection [key]; on first read (or corrupt stored JSON) calls
  /// [seed] and persists the result — mirrors `getCollection` in
  /// `mock-db.ts`, including the SSR-safe short-circuit there (irrelevant
  /// on-device, since there's no server render step here).
  static List<T> getCollection<T>(
    String key,
    List<T> Function() seed,
    T Function(Map<String, dynamic> json) fromJson,
    Map<String, dynamic> Function(T value) toJson,
  ) {
    final raw = _instance.getString('$_prefix$key');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        // Falls through to reseed, same as a JSON.parse failure on web.
      }
    }
    final seeded = seed();
    setCollection(key, seeded, toJson);
    return seeded;
  }

  /// Drops every collection this app owns.
  ///
  /// Only the `gz-db-v1:` keys are removed, never the whole preference store —
  /// other plugins keep their own keys in there, and an account deletion has
  /// no business clearing them. Backs the in-app delete-account flow, which
  /// Google Play requires of any app with accounts.
  static Future<void> clearAll() async {
    final keys = _instance.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _instance.remove(key);
    }
  }

  /// Overwrites collection [key] — mirrors `setCollection` in `mock-db.ts`.
  static void setCollection<T>(
    String key,
    List<T> value,
    Map<String, dynamic> Function(T value) toJson,
  ) {
    _instance.setString('$_prefix$key', jsonEncode(value.map(toJson).toList()));
  }
}
