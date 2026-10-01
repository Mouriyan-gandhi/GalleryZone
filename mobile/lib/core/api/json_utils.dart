/// Wire-format helpers shared by every mapper.
///
/// The API speaks integer **paise** and the app's models hold **rupees**
/// (`double`), so conversion happens once, at the mapper boundary — the same
/// split `lib/api-mappers.ts` makes on the web. Nothing past a mapper ever
/// sees a paise value.
library;

/// `250000` paise -> `2500.0` rupees. Mirrors the web's
/// `Math.round(paise) / 100`.
double paiseToRupees(num paise) => paise.round() / 100;

/// `2500.0` rupees -> `250000` paise, rounded so a float like `1999.99`
/// cannot leave a stray fraction of a paisa on the wire.
int rupeesToPaise(num rupees) => (rupees * 100).round();

/// Timestamps arrive either as an ISO string or, from routes that spread a
/// raw Firestore document, as `{_seconds, _nanoseconds}`. Both come back as a
/// [DateTime]; `null`/garbage is `null`.
DateTime? parseTimestamp(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : DateTime.tryParse(value);
  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      final nanos = value['_nanoseconds'] ?? value['nanoseconds'];
      final millis = seconds.toInt() * 1000 + ((nanos is num ? nanos.toInt() : 0) ~/ 1000000);
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
  }
  return null;
}

/// [parseTimestamp] as the ISO-8601 string the models keep (they store dates
/// as strings, like the web's types). Empty when absent.
String isoOf(Object? value) => parseTimestamp(value)?.toUtc().toIso8601String() ?? '';

/// [isoOf], but `null` when absent — for nullable date fields.
String? isoOrNull(Object? value) => parseTimestamp(value)?.toUtc().toIso8601String();

/// Reads `json[key]` as a map, or an empty one — so a mapper can chain
/// without a null check at every level.
Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Reads a JSON list of objects, ignoring anything that is not one.
List<Map<String, dynamic>> asMapList(Object? value) => value is List
    ? [for (final item in value) if (item is Map) Map<String, dynamic>.from(item)]
    : <Map<String, dynamic>>[];

/// The `paise` field of [json] as rupees, or [orElse] when it is absent.
double rupeesAt(Map<String, dynamic> json, String key, {double orElse = 0}) {
  final value = json[key];
  return value is num ? paiseToRupees(value) : orElse;
}

/// A nullable paise field as nullable rupees.
double? rupeesAtOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? paiseToRupees(value) : null;
}
