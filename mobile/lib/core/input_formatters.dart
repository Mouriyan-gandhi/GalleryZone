import 'package:flutter/services.dart';

/// Capitals as you type: a GSTIN, an IFSC or a PAN is only ever written in them, and
/// the person shouldn't have to hold shift or be told off afterwards.
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
