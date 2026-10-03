/// Dial codes for the company and coordinator phone numbers. Port of
/// `features/aggregator/country-codes.ts`: India first and selected by default -
/// GalleryZone aggregators are India-based gallery and retail partners - and the
/// rest cover the other countries support most commonly hears from.
class CountryCode {
  const CountryCode({required this.dial, required this.iso, required this.label});

  final String dial;
  final String iso;
  final String label;
}

const countryCodes = <CountryCode>[
  CountryCode(dial: '+91', iso: 'IN', label: 'India'),
  CountryCode(dial: '+1', iso: 'US', label: 'United States'),
  CountryCode(dial: '+44', iso: 'GB', label: 'United Kingdom'),
  CountryCode(dial: '+971', iso: 'AE', label: 'UAE'),
  CountryCode(dial: '+65', iso: 'SG', label: 'Singapore'),
  CountryCode(dial: '+61', iso: 'AU', label: 'Australia'),
  CountryCode(dial: '+974', iso: 'QA', label: 'Qatar'),
  CountryCode(dial: '+966', iso: 'SA', label: 'Saudi Arabia'),
  CountryCode(dial: '+49', iso: 'DE', label: 'Germany'),
  CountryCode(dial: '+33', iso: 'FR', label: 'France'),
  CountryCode(dial: '+81', iso: 'JP', label: 'Japan'),
];

const defaultCountryDial = '+91';

/// Splits a stored `+91 98450 33127` style phone into a known dial code and the
/// rest. Falls back to the default dial code when the value doesn't start with a
/// recognised one followed by a space (a legacy number with no code).
({String dial, String number}) splitPhone(String? value) {
  final trimmed = (value ?? '').trim();
  for (final code in countryCodes) {
    if (trimmed.startsWith('${code.dial} ')) {
      return (dial: code.dial, number: trimmed.substring(code.dial.length).trim());
    }
  }
  return (dial: defaultCountryDial, number: trimmed);
}

String joinPhone(String dial, String number) => '$dial ${number.trim()}'.trim();

/// A number's local part (dial code stripped off) has to be 6 to 14 digits whichever
/// country it is from: E.164 caps the whole number at 15 digits, and nothing real
/// is shorter than 6. Spaces are ignored.
final _phoneNumberPattern = RegExp(r'^[0-9]{6,14}$');

bool isValidPhoneNumber(String value) => _phoneNumberPattern.hasMatch(value.replaceAll(RegExp(r'\s+'), ''));
