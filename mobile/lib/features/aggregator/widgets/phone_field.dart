import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../country_codes.dart';

/// The two halves of a phone number: the dial code picked from a list, and the
/// number typed beside it. [value] joins them the way the API stores it.
class PhoneController extends ChangeNotifier {
  PhoneController([String? stored]) {
    final parts = splitPhone(stored);
    _dial = parts.dial;
    number = TextEditingController(text: parts.number);
  }

  late String _dial;
  late final TextEditingController number;

  /// Replaces both halves from a stored number, e.g. once the profile has loaded.
  void load(String? stored) {
    final parts = splitPhone(stored);
    number.text = parts.number;
    dial = parts.dial;
  }

  String get dial => _dial;

  set dial(String value) {
    if (value == _dial) return;
    _dial = value;
    notifyListeners();
  }

  /// `+91 98450 12345`.
  String get value => joinPhone(_dial, number.text);

  @override
  void dispose() {
    number.dispose();
    super.dispose();
  }
}

/// A phone field with a dial-code button in front of it. Port of the website's
/// `DialCodePicker` + phone input: the picker is a sheet rather than a popover.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
  });

  final PhoneController controller;
  final String label;
  final bool enabled;
  final String? Function(String)? validator;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<CountryCode>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Select dial code', style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final code in countryCodes)
                    ListTile(
                      title: Text(code.label),
                      trailing: Text(code.dial, style: Theme.of(context).textTheme.bodyMedium),
                      selected: code.dial == controller.dial,
                      onTap: () => Navigator.of(context).pop(code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) controller.dial = picked.dial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              button: true,
              label: 'Dial code ${controller.dial}',
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: enabled ? () => _pick(context) : null,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.dial, style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller.number,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
              decoration: InputDecoration(labelText: label),
              validator: validator == null ? null : (value) => validator!(value ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}
