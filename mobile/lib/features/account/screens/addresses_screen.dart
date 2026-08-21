import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';

/// Port of `app/account/addresses/page.tsx` + `address-card.tsx` +
/// `address-form-dialog.tsx`. Add/edit share one form sheet — the fields are
/// identical, and two near-copies would drift.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  static const path = '/account/addresses';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Add address'),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your addresses",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.mapPin,
                title: 'No saved addresses',
                description: 'Add one here, or during checkout — they end up in the same book.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => ContentWidth(
                  child: _AddressCard(
                    address: list[index],
                    onEdit: () => _openForm(context, ref, list[index]),
                    onDelete: () => _confirmDelete(context, ref, list[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, Address? existing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AddressFormSheet(existing: existing),
    );
    if (saved ?? false) ref.invalidate(addressesProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this address?'),
        content: Text('${address.line1}, ${address.city} will be removed from your address book.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await ref.read(customerRepositoryProvider).deleteAddress(address.id);
      ref.invalidate(addressesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onEdit, required this.onDelete});

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.mapPin, size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.line1,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl4),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Default',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.tertiary),
                        ),
                      ),
                    ],
                  ],
                ),
                if (address.line2 != null) Text(address.line2!, style: theme.textTheme.bodySmall),
                Text(
                  '${address.city}, ${address.state} ${address.pincode}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(LucideIcons.pencil, size: 16),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete',
            icon: Icon(LucideIcons.trash2, size: 16, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({this.existing});

  final Address? existing;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _line1 = TextEditingController(text: widget.existing?.line1 ?? '');
  late final _line2 = TextEditingController(text: widget.existing?.line2 ?? '');
  late final _city = TextEditingController(text: widget.existing?.city ?? '');
  late final _state = TextEditingController(text: widget.existing?.state ?? '');
  late final _pincode = TextEditingController(text: widget.existing?.pincode ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [_line1, _line2, _city, _state, _pincode]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final repository = ref.read(customerRepositoryProvider);
    final address = Address(
      id: widget.existing?.id ?? '',
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      isDefault: _isDefault,
    );
    try {
      if (widget.existing == null) {
        await repository.addAddress(address);
      } else {
        await repository.updateAddress(address);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add address' : 'Edit address',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _field(_line1, 'Address line 1',
                  (v) => (v ?? '').trim().length < 3 ? 'Enter the address line' : null),
              _field(_line2, 'Address line 2 (optional)', null),
              _field(_city, 'City', (v) => (v ?? '').trim().length < 2 ? 'Enter the city' : null),
              _field(_state, 'State', (v) => (v ?? '').trim().length < 2 ? 'Enter the state' : null),
              _field(
                _pincode,
                'Pincode',
                (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid 6-digit pincode',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                title: const Text('Use as default address'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving…' : 'Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    FormFieldValidator<String>? validator, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
