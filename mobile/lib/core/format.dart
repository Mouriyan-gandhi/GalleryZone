import 'package:intl/intl.dart';

/// Port of `lib/utils.ts`'s `formatINR` — `en_IN` grouping (lakh/crore, not
/// thousands), no paise. Every ₹ amount in the app renders through this.
String formatInr(num amount) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);

/// `4 March 2025` — the long form the web uses on artwork detail and the
/// passport certificate. No locale argument: date symbols for anything but
/// the default locale need `initializeDateFormatting()` at startup, and
/// `en_IN` renders these two patterns identically to the default anyway.
String formatLongDate(String iso) =>
    DateFormat('d MMMM y').format(DateTime.parse(iso));

/// `4 Mar 2025` — the short form the provenance timeline uses.
String formatShortDate(String iso) =>
    DateFormat('d MMM y').format(DateTime.parse(iso));

/// `oil on canvas` -> `Oil On Canvas`. Port of the marketplace filter bar's
/// `titleCase`, used wherever a raw category string is shown as a label.
String titleCase(String value) => value
    .split(' ')
    .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
