import 'package:flutter/material.dart';

import '../../legal/data/faq_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../data/mock/seed/artist_seed.dart';
import '../../../data/models/artist_portal.dart';
import '../../account/widgets/delete_account.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';
import '../widgets/deactivation_tile.dart';

/// Port of `app/dashboard/settlements/page.tsx` — one record per sale,
/// showing exactly how the money split.
class ArtistSettlementsScreen extends ConsumerWidget {
  const ArtistSettlementsScreen({super.key});

  static const path = '/dashboard/settlements';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settlements = ref.watch(artistSettlementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: settlements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your settlements",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.receipt,
                title: 'No settlements yet',
                description: 'Each confirmed sale produces a settlement record here.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The commission split is an open product decision
                        // (mocked code, a business requirement and the SAD's
                        // schema disagree), so these figures are labelled as
                        // provisional rather than presented as final.
                        PortalCard(
                          gold: true,
                          child: Row(
                            children: [
                              Icon(LucideIcons.info, size: 15, color: theme.colorScheme.tertiary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Commission split is provisional in this build — the '
                                  'final formula is still being confirmed.',
                                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final settlement in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PortalCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          settlement.artworkTitle,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        settlement.status.name,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),
                                  PortalDetailRow(
                                    label: 'Your payout',
                                    value: formatInr(settlement.artistAmount),
                                    gold: true,
                                  ),
                                  PortalDetailRow(
                                    label: 'Aggregator commission',
                                    value: formatInr(settlement.aggregatorCommission),
                                  ),
                                  PortalDetailRow(
                                    label: 'Platform revenue',
                                    value: formatInr(settlement.platformRevenue),
                                  ),
                                  PortalDetailRow(
                                    label: 'Processed',
                                    value: settlement.processedAt == null
                                        ? 'Pending'
                                        : formatLongDate(settlement.processedAt!),
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

/// Port of `app/dashboard/verification/page.tsx` — the three-tier ladder to
/// the Gold ✦ Verified badge, with what each tier actually requires.
class ArtistVerificationScreen extends StatelessWidget {
  const ArtistVerificationScreen({super.key});

  static const path = '/dashboard/verification';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiers = artistVerificationTiers();

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Three tiers unlock the Gold ✦ Verified badge shown on your public '
                  'profile and every listing.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                for (final tier in tiers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PortalCard(
                      gold: tier.status == VerificationTierStatus.active,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                tier.status == VerificationTierStatus.complete
                                    ? LucideIcons.circleCheckBig
                                    : LucideIcons.circle,
                                size: 16,
                                color: tier.status == VerificationTierStatus.complete
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tier ${tier.tier}: ${tier.title}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (tier.completedOn != null)
                                Text(
                                  formatShortDate(tier.completedOn!),
                                  style: theme.textTheme.labelSmall,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tier.detail,
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
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
    );
  }
}

/// Port of `features/dashboard/messages-inbox.tsx` — one-way notices from
/// GalleryZone. There is no reply path: the web has none either, and a
/// compose box that goes nowhere would be a lie.
class ArtistMessagesScreen extends ConsumerWidget {
  const ArtistMessagesScreen({super.key});

  static const path = '/dashboard/messages';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messages = ref.watch(artistMessagesProvider);

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
                description: 'Notices about submissions, KYC and settlements land here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = list[index];
                  return ContentWidth(
                    child: PortalCard(
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        // Opening a thread is what marks it read — the same
                        // moment the artist has actually seen it.
                        onExpansionChanged: (expanded) async {
                          if (!expanded || !message.unread) return;
                          await ref.read(artistRepositoryProvider).markMessageRead(message.id);
                          ref.invalidate(artistMessagesProvider);
                        },
                        title: Row(
                          children: [
                            if (message.unread) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                message.subject,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: message.unread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${message.from} · ${formatShortDate(message.receivedAt)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              message.body,
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Port of `features/dashboard/profile-kyc-form.tsx`. Identity and bank
/// detail; the full account number is never stored, only its last four.
/// 2-digit state code, PAN, entity digit, Z, checksum char. Shape only: the
/// business deliberately does not want a GST portal integration.
final _gstinPattern = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

/// Indian pincodes never start with 0.
final _pincodePattern = RegExp(r'^[1-9][0-9]{5}$');

/// Named `Kyc`, not `Profile`, to stay distinct from the *public* artist
/// profile a collector browses.
class ArtistKycScreen extends ConsumerStatefulWidget {
  const ArtistKycScreen({super.key});

  static const path = '/dashboard/profile';

  @override
  ConsumerState<ArtistKycScreen> createState() => _ArtistKycScreenState();
}

class _ArtistKycScreenState extends ConsumerState<ArtistKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _gstin = TextEditingController();
  final _pickupLine1 = TextEditingController();
  final _pickupLine2 = TextEditingController();
  final _pickupCity = TextEditingController();
  final _pickupState = TextEditingController();
  final _pickupPincode = TextEditingController();
  bool _isSeeded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _email,
      _phone,
      _bio,
      _instagram,
      _website,
      _gstin,
      _pickupLine1,
      _pickupLine2,
      _pickupCity,
      _pickupState,
      _pickupPincode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(ArtistProfileDetails current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(artistRepositoryProvider)
          .updateProfile(
            current.copyWith(
              fullName: _fullName.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              bio: _bio.text.trim(),
              instagram: _instagram.text.trim(),
              website: _website.text.trim(),
              gstin: _gstin.text.trim().isEmpty ? null : _gstin.text.trim().toUpperCase(),
              pickupLine1: _pickupLine1.text.trim(),
              pickupLine2: _pickupLine2.text.trim(),
              pickupCity: _pickupCity.text.trim(),
              pickupState: _pickupState.text.trim(),
              pickupPincode: _pickupPincode.text.trim(),
            ),
          );
      ref.invalidate(artistProfileDetailsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(artistProfileDetailsProvider);
    final loaded = profile.value;

    if (!_isSeeded && loaded != null) {
      _isSeeded = true;
      _fullName.text = loaded.fullName;
      _email.text = loaded.email;
      _phone.text = loaded.phone;
      _bio.text = loaded.bio;
      _instagram.text = loaded.instagram;
      _website.text = loaded.website;
      _gstin.text = loaded.gstin ?? '';
      _pickupLine1.text = loaded.pickupLine1;
      _pickupLine2.text = loaded.pickupLine2;
      _pickupCity.text = loaded.pickupCity;
      _pickupState.text = loaded.pickupState;
      _pickupPincode.text = loaded.pickupPincode;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & KYC')),
      body: loaded == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  maxWidth: 560,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _fullName,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) =>
                              (value ?? '').trim().length < 2 ? 'Enter your name' : null,
                          decoration: const InputDecoration(labelText: 'Full name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bio,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(labelText: 'Bio'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _instagram,
                          decoration: const InputDecoration(
                            labelText: 'Instagram handle (optional)',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _website,
                          decoration: const InputDecoration(
                            labelText: 'Website (optional)',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _gstin,
                          textCapitalization: TextCapitalization.characters,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final entered = (value ?? '').trim().toUpperCase();
                            if (entered.isEmpty) return null;
                            return _gstinPattern.hasMatch(entered)
                                ? null
                                : "That doesn't look like a valid GSTIN";
                          },
                          decoration: const InputDecoration(
                            labelText: 'GSTIN (optional)',
                            helperText:
                                'Checked for format only — we never call the '
                                'GST portal. Leave it blank if you are not registered.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Pickup address', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Where your work is collected from. Private — buyers '
                          'never see it.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                        if (!loaded.hasPickupAddress) ...[
                          const SizedBox(height: 10),
                          PortalCard(
                            gold: true,
                            child: Text(
                              'Add this before your first sale. Delivery is '
                              "priced on the distance between your address and "
                              "the buyer's, so without it we can't quote a "
                              'shipping cost for your work.',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pickupLine1,
                          decoration: const InputDecoration(
                            labelText: 'Address line 1',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pickupLine2,
                          decoration: const InputDecoration(
                            labelText: 'Address line 2 (optional)',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pickupCity,
                                decoration:
                                    const InputDecoration(labelText: 'City'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _pickupState,
                                decoration:
                                    const InputDecoration(labelText: 'State'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pickupPincode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final entered = (value ?? '').trim();
                            if (entered.isEmpty) return null;
                            return _pincodePattern.hasMatch(entered)
                                ? null
                                : 'Enter a valid 6-digit pincode';
                          },
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                            helperText:
                                'This is what a courier prices the distance from.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: _isSaving ? null : () => _save(loaded),
                            child: Text(_isSaving ? 'Saving…' : 'Save profile'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Identity', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        PortalCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PortalDetailRow(
                                label: 'Aadhaar',
                                value: '${loaded.aadhaarMasked} · ${loaded.aadhaarStatus.name}',
                                gold: loaded.aadhaarStatus == AadhaarStatus.verified,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Identity documents',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submit an additional ID or address proof if support '
                                'has requested one for your account. PAN is preferred '
                                '(optional). Contact support to send one — uploads are '
                                'not wired up in this build.',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Port of `features/dashboard/artist-settings-view.tsx` — notification
/// preferences only. Nothing else here controls a system that exists yet.
class ArtistSettingsScreen extends ConsumerWidget {
  const ArtistSettingsScreen({super.key});

  static const path = '/dashboard/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(artistSettingsProvider).value;

    Future<void> update(ArtistSettings next) async {
      await ref.read(artistRepositoryProvider).updateSettings(next);
      ref.invalidate(artistSettingsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  maxWidth: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SubscriptionCard(),
                      const SizedBox(height: 24),
                      Text('Notify me about', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.notifyArtworkApproved,
                        onChanged: (value) =>
                            update(settings.copyWith(notifyArtworkApproved: value)),
                        title: const Text('Artwork approvals'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.notifyNewSale,
                        onChanged: (value) => update(settings.copyWith(notifyNewSale: value)),
                        title: const Text('New sales'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.notifyWithdrawalProcessed,
                        onChanged: (value) =>
                            update(settings.copyWith(notifyWithdrawalProcessed: value)),
                        title: const Text('Withdrawals processed'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.notifyNewMessage,
                        onChanged: (value) => update(settings.copyWith(notifyNewMessage: value)),
                        title: const Text('New messages'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Push delivery is not wired up in this build — these only '
                        'record your preference.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                      ),
                      const Divider(height: 32),
                      const DeactivationTile(),
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

/// Static plan card — every artist is on the founding-member plan (free for
/// the first year) and there is no billing system to read a real plan from
/// yet. It exists so the artist can see the benefit they are on.
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  static const _planName = 'Founding Artist';
  static const _priceLabel = 'Free for your first year';
  static const _renewsOn = '2027-07-05';
  static const _benefits = [
    'Unlimited artwork listings',
    '0% listing and confirmation fees',
    'Aggregator display access',
    'COA and NFC passport for every accepted piece',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.badgeCheck, size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_planName plan',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _priceLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text('Active', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          for (final benefit in _benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.check, size: 13, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(benefit, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          const Divider(height: 20),
          Text(
            'Renews ${formatLongDate(_renewsOn)}. Nothing to pay until then, and we '
            'will tell you well before anything changes.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Port of `features/dashboard/support-view.tsx` — same honest mock as the
/// collector's: tickets are recorded locally, not sent to a live inbox.
class ArtistSupportScreen extends ConsumerStatefulWidget {
  const ArtistSupportScreen({super.key});

  static const path = '/dashboard/support';

  @override
  ConsumerState<ArtistSupportScreen> createState() => _ArtistSupportScreenState();
}

class _ArtistSupportScreenState extends ConsumerState<ArtistSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(artistRepositoryProvider)
          .submitSupportTicket(subject: _subject.text, message: _message.text);
      ref.invalidate(artistSupportTicketsProvider);
      _subject.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = ref.watch(artistSupportTicketsProvider).value ?? const [];

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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SupportFaqPanel(audience: FaqAudience.artists),
                const SizedBox(height: 24),
                Text('Raise a ticket', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _subject,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? 'A subject is required' : null,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _message,
                        minLines: 3,
                        maxLines: 6,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) =>
                            (value ?? '').trim().isEmpty ? 'Enter a message' : null,
                        decoration: const InputDecoration(labelText: 'Message'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _isSending ? null : _submit,
                          child: Text(_isSending ? 'Sending…' : 'Submit ticket'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Your tickets', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (tickets.isEmpty)
                  Text('No tickets yet.', style: theme.textTheme.bodySmall)
                else
                  for (final ticket in tickets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PortalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.subject,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(ticket.status.name, style: theme.textTheme.labelSmall),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(ticket.message, style: theme.textTheme.bodySmall),
                            const SizedBox(height: 6),
                            Text(
                              formatShortDate(ticket.createdAt),
                              style: theme.textTheme.labelSmall,
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
    );
  }
}
