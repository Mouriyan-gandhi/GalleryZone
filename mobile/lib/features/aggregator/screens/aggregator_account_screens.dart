import 'package:flutter/material.dart';

import '../../legal/data/faq_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/launch.dart';
import '../../../core/format.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/customer.dart';
import '../../account/widgets/delete_account.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `features/aggregator/gallery-spaces-board.tsx` — the aggregator's
/// own premises. Not the artist portal's screen of the same name, which
/// lists an artist's pieces sitting *at* an aggregator.
class AggregatorGallerySpacesScreen extends ConsumerWidget {
  const AggregatorGallerySpacesScreen({super.key});

  static const path = '/aggregator/dashboard/gallery-spaces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spaces = ref.watch(aggregatorGallerySpacesProvider);
    // Only one premises concept is modelled, so every active holding counts
    // against it.
    final occupancy = (ref.watch(aggregatorCollectionProvider).value ?? const [])
        .where((view) => view.holding.status == HoldingStatus.reserved)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Display Spaces')),
      body: spaces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your display spaces",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.building2,
                title: 'No display spaces on file',
                description:
                    'Your display premises appear here once registered with '
                    'GalleryZone.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final space in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PortalCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.building2,
                                          size: 16, color: theme.colorScheme.tertiary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(space.name,
                                            style: theme.textTheme.titleMedium),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  PortalDetailRow(
                                    label: 'Address',
                                    value: '${space.addressLine1}, ${space.city}, '
                                        '${space.state} ${space.pincode}',
                                  ),
                                  PortalDetailRow(
                                      label: 'Coordinator',
                                      value: space.coordinatorName),
                                  PortalDetailRow(
                                    label: 'Occupancy',
                                    value: '$occupancy / ${space.capacity}',
                                    gold: occupancy >= space.capacity,
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value:
                                        (occupancy / space.capacity).clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: theme.colorScheme.outline,
                                    valueColor:
                                        AlwaysStoppedAnimation(theme.colorScheme.tertiary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Port of `features/aggregator/messages-inbox.tsx`. The fixtures are flat
/// single-message threads, not conversations, so click-to-expand is the
/// honest amount of UI.
class AggregatorMessagesScreen extends ConsumerStatefulWidget {
  const AggregatorMessagesScreen({super.key});

  static const path = '/aggregator/dashboard/messages';

  @override
  ConsumerState<AggregatorMessagesScreen> createState() =>
      _AggregatorMessagesScreenState();
}

class _AggregatorMessagesScreenState extends ConsumerState<AggregatorMessagesScreen> {
  String? _expandedId;

  Future<void> _toggle(MessageThread message) async {
    final opening = _expandedId != message.id;
    setState(() => _expandedId = opening ? message.id : null);
    if (!opening || !message.unread) return;
    await ref.read(aggregatorRepositoryProvider).markMessageRead(message.id);
    ref.invalidate(aggregatorMessagesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(aggregatorMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your messages",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.mail,
                title: 'No messages',
                description:
                    'Notices about assignments, audits and settlements show up here.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final message in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PortalCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  ListTile(
                                    onTap: () => _toggle(message),
                                    leading: Icon(
                                      message.unread
                                          ? LucideIcons.mail
                                          : LucideIcons.mailOpen,
                                      size: 18,
                                      color: message.unread
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.outline,
                                    ),
                                    title: Text(
                                      message.subject,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: message.unread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${message.from} · '
                                      '${formatShortDate(message.receivedAt)}',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    trailing: Icon(
                                      _expandedId == message.id
                                          ? LucideIcons.chevronUp
                                          : LucideIcons.chevronDown,
                                      size: 16,
                                    ),
                                  ),
                                  if (_expandedId == message.id)
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Text(
                                        message.body,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Port of `features/aggregator/profile-form.tsx` — company details, the
/// security-deposit status, and the bank account. Only the last four digits
/// of an account number are ever stored.
class AggregatorProfileScreen extends ConsumerStatefulWidget {
  const AggregatorProfileScreen({super.key});

  static const path = '/aggregator/dashboard/profile';

  @override
  ConsumerState<AggregatorProfileScreen> createState() =>
      _AggregatorProfileScreenState();
}

class _AggregatorProfileScreenState extends ConsumerState<AggregatorProfileScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _bankKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _gst = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc = TextEditingController();

  /// Seeded once from the loaded profile; after that the fields are the
  /// user's to edit, and a background refetch must not overwrite them.
  bool _seeded = false;

  @override
  void dispose() {
    for (final controller in [
      _company,
      _contact,
      _gst,
      _phone,
      _address,
      _accountNumber,
      _ifsc,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seed(AggregatorProfile profile) {
    if (_seeded) return;
    _seeded = true;
    _company.text = profile.companyName;
    _contact.text = profile.contactPerson;
    _gst.text = profile.gstNumber;
    _phone.text = profile.phone;
    _address.text = profile.addressLine1;
    _ifsc.text = profile.ifsc;
  }

  Future<void> _saveProfile(AggregatorProfile current) async {
    if (!_profileKey.currentState!.validate()) return;
    try {
      await ref.read(aggregatorRepositoryProvider).updateProfile(
            current.copyWith(
              companyName: _company.text.trim(),
              contactPerson: _contact.text.trim(),
              gstNumber: _gst.text.trim().toUpperCase(),
              phone: _phone.text.trim(),
              addressLine1: _address.text.trim(),
            ),
          );
      ref.invalidate(aggregatorProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  Future<void> _saveBank() async {
    if (!_bankKey.currentState!.validate()) return;
    try {
      await ref.read(aggregatorRepositoryProvider).updateBankDetails(
            accountNumber: _accountNumber.text,
            ifsc: _ifsc.text,
          );
      ref.invalidate(aggregatorProfileProvider);
      _accountNumber.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bank details updated')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(aggregatorProfileProvider).value;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _seed(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Company profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _profileKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _company,
                        decoration: const InputDecoration(labelText: 'Company name'),
                        validator: (value) => (value ?? '').trim().length < 2
                            ? 'Enter your company name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contact,
                        decoration: const InputDecoration(labelText: 'Contact person'),
                        validator: (value) => (value ?? '').trim().length < 2
                            ? 'Enter a contact person'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gst,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 15,
                        decoration: const InputDecoration(labelText: 'GST number'),
                        validator: (value) => (value ?? '').trim().length != 15
                            ? 'GST number must be 15 characters'
                            : null,
                      ),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (value) => (value ?? '').trim().length < 10
                            ? 'Enter a valid phone number'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration:
                            const InputDecoration(labelText: 'Business address'),
                        validator: (value) => (value ?? '').trim().length < 5
                            ? 'Enter your business address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: () => _saveProfile(profile),
                          child: const Text('Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PortalCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Security deposit',
                                style: theme.textTheme.titleMedium),
                          ),
                          StatusPill(
                            label: titleCase(profile.securityDepositStatus),
                            color: const Color(0xFF34D399),
                            icon: LucideIcons.shieldCheck,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Held per your onboarding MOU and refunded after a final '
                        'audit if you exit the program. Managed by GalleryZone admin '
                        '— contact support with questions.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bank account', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                PortalCard(
                  child: Row(
                    children: [
                      Icon(LucideIcons.lock, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.bankAccountMasked,
                                style: theme.textTheme.bodyMedium),
                            Text('${profile.ifsc} · currently on file',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _bankKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _accountNumber,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'New account number',
                          helperText: 'Only the last 4 digits are ever stored.',
                        ),
                        validator: (value) => (value ?? '').trim().length < 4
                            ? 'Enter your account number'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ifsc,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 11,
                        decoration: const InputDecoration(labelText: 'IFSC code'),
                        validator: (value) =>
                            RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
                                    .hasMatch((value ?? '').trim().toUpperCase())
                                ? null
                                : 'Enter a valid IFSC code',
                      ),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _saveBank,
                          child: const Text('Update bank details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Port of `features/aggregator/settings-view.tsx`.
class AggregatorSettingsScreen extends ConsumerWidget {
  const AggregatorSettingsScreen({super.key});

  static const path = '/aggregator/dashboard/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(aggregatorSettingsProvider).value;

    Future<void> update(AggregatorSettings next) async {
      await ref.read(aggregatorRepositoryProvider).updateSettings(next);
      ref.invalidate(aggregatorSettingsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Notifications', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('New artwork assigned or reserved'),
                        value: settings.notifyNewAssignment,
                        onChanged: (value) =>
                            update(settings.copyWith(notifyNewAssignment: value)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sale recorded'),
                        value: settings.notifySaleRecorded,
                        onChanged: (value) =>
                            update(settings.copyWith(notifySaleRecorded: value)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Settlement processed'),
                        value: settings.notifySettlementProcessed,
                        onChanged: (value) =>
                            update(settings.copyWith(notifySettlementProcessed: value)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('30-day display window expiring soon'),
                        value: settings.notifyExpiryReminder,
                        onChanged: (value) =>
                            update(settings.copyWith(notifyExpiryReminder: value)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Push delivery is not wired up in this build — these only '
                        'record your preference.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                      ),
                      const Divider(height: 32),
                      const DeleteAccountTile(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Port of `features/aggregator/support-view.tsx`. Tickets aren't wired to a
/// live inbox — the same honest-mock posture as the artist portal's screen.
class AggregatorSupportScreen extends ConsumerStatefulWidget {
  const AggregatorSupportScreen({super.key});

  static const path = '/aggregator/dashboard/support';

  @override
  ConsumerState<AggregatorSupportScreen> createState() =>
      _AggregatorSupportScreenState();
}

class _AggregatorSupportScreenState extends ConsumerState<AggregatorSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  static const _faq = <({IconData icon, String question, String answer})>[
    (
      icon: LucideIcons.percent,
      question: 'How is my commission calculated?',
      answer:
          '20% of the difference between your display price and the GalleryZone '
          'customer price (Profit Share = 20% × (Listed Price − Artist Price)). Paid '
          'only after full customer payment, delivery, and any return window closes.',
    ),
    (
      icon: LucideIcons.clock3,
      question: 'How long can I hold a reserved artwork?',
      answer:
          '30 days from the reservation date, unless otherwise approved by '
          'GalleryZone. Unsold pieces may be relocated to another aggregator or sales '
          'channel after that.',
    ),
    (
      icon: LucideIcons.packageCheck,
      question: "What's the advance payment for reserving an artwork?",
      answer:
          "5% or 3% of the artwork's value plus applicable delivery charges, paid "
          'before you take possession for display. This is adjusted upon successful '
          'sale.',
    ),
  ];

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(aggregatorRepositoryProvider).submitSupportTicket(
            subject: _subject.text,
            message: _message.text,
          );
      ref.invalidate(aggregatorSupportTicketsProvider);
      _subject.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ticket submitted')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = ref.watch(aggregatorSupportTicketsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  gold: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact GalleryZone', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ContactLinkRow(
                        icon: LucideIcons.mail,
                        label: galleryZoneEmail,
                        url: 'mailto:$galleryZoneEmail',
                      ),
                      ContactLinkRow(
                        icon: LucideIcons.phone,
                        label: '+91 94929 53627',
                        url: 'tel:$galleryZonePhone',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Frequently asked', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final item in _faq)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PortalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.icon, size: 15, color: theme.colorScheme.tertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.question,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(item.answer,
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const SupportFaqPanel(audience: FaqAudience.aggregators),
                const SizedBox(height: 24),
                Text('Raise a ticket', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  "This demo doesn't send to a live inbox — for real issues, email us "
                  'directly above.',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _subject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'e.g. Question about my advance payment',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'A subject is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _message,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Describe your issue…',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? 'Enter a message' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text('Submit ticket'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (tickets.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Your tickets', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final ticket in tickets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PortalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.subject,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                _TicketStatusPill(status: ticket.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(ticket.message,
                                style: theme.textTheme.labelSmall?.copyWith(height: 1.45)),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketStatusPill extends StatelessWidget {
  const _TicketStatusPill({required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      SupportTicketStatus.open =>
        StatusPill(label: 'Open', color: theme.colorScheme.tertiary),
      SupportTicketStatus.answered =>
        const StatusPill(label: 'Answered', color: Color(0xFF34D399)),
      SupportTicketStatus.closed =>
        StatusPill(label: 'Closed', color: theme.colorScheme.outline),
    };
  }
}
