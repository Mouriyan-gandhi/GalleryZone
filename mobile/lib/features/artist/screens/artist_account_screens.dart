import 'package:flutter/material.dart';

import '../../legal/data/faq_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/auth.dart' show ForgotPasswordInput;
import '../../account/widgets/delete_account.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';
import '../widgets/deactivation_tile.dart';

/// Port of `app/dashboard/verification/page.tsx` — the three-tier ladder to
/// the Gold ✦ Verified badge, with what each tier actually requires.
class ArtistVerificationScreen extends ConsumerWidget {
  const ArtistVerificationScreen({super.key});

  static const path = '/dashboard/verification';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Worked out from the profile, the signed agreement and the artworks - not
    // a fixed list - so each rung is ticked when it is true.
    final tiers = ref.watch(verificationTiersProvider);

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
                                color:
                                    tier.status ==
                                        VerificationTierStatus.complete
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
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
    );
  }
}

/// Port of `features/dashboard/messages-inbox.tsx` - one-way notices from
/// GalleryZone. There is no reply path: the web has none either, and a compose
/// box that goes nowhere would be a lie.
///
/// A click-to-expand row rather than a two-pane inbox, as on the website: the
/// messages are flat single-message threads, not conversations. Opening one is
/// what marks it read.
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
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your messages",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(artistMessagesProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.mail,
                title: 'No messages',
                description: 'Updates from GalleryZone about your submissions, sales, and account will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(artistMessagesProvider);
                  await ref.read(artistMessagesProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = list[index];
                    return ContentWidth(
                      child: PortalCard(
                        padding: EdgeInsets.zero,
                        // A Material of its own, or the card's decoration hides the
                        // tile's ink (and debug builds say so).
                        child: Material(
                          type: MaterialType.transparency,
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              14,
                              0,
                              14,
                              14,
                            ),
                            leading: Icon(
                              message.unread
                                  ? LucideIcons.mail
                                  : LucideIcons.mailOpen,
                              size: 16,
                              color: message.unread
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            // Opening a thread is what marks it read - the same
                            // moment the artist has actually seen it.
                            onExpansionChanged: (expanded) async {
                              if (!expanded || !message.unread) return;
                              await ref
                                  .read(artistRepositoryProvider)
                                  .markMessageRead(message.id);
                              ref.invalidate(artistMessagesProvider);
                            },
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message.subject,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: message.unread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDay(message.receivedAt),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${message.from} · ${message.preview}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  message.body,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// Port of `features/dashboard/artist-settings-view.tsx`: the plan, which
/// notices to receive, how to secure the account, and - at the foot - closing it.
class ArtistSettingsScreen extends ConsumerWidget {
  const ArtistSettingsScreen({super.key});

  static const path = '/dashboard/settings';

  static const _toggles =
      <
        ({
          String label,
          ArtistSettings Function(ArtistSettings, bool) set,
          bool Function(ArtistSettings) get,
        })
      >[
        (
          label: 'Artwork approved or rejected',
          get: _approved,
          set: _setApproved,
        ),
        (label: 'New sale', get: _sale, set: _setSale),
        (label: 'Withdrawal processed', get: _withdrawal, set: _setWithdrawal),
        (label: 'New message', get: _message, set: _setMessage),
      ];

  static bool _approved(ArtistSettings s) => s.notifyArtworkApproved;
  static ArtistSettings _setApproved(ArtistSettings s, bool v) =>
      s.copyWith(notifyArtworkApproved: v);
  static bool _sale(ArtistSettings s) => s.notifyNewSale;
  static ArtistSettings _setSale(ArtistSettings s, bool v) =>
      s.copyWith(notifyNewSale: v);
  static bool _withdrawal(ArtistSettings s) => s.notifyWithdrawalProcessed;
  static ArtistSettings _setWithdrawal(ArtistSettings s, bool v) =>
      s.copyWith(notifyWithdrawalProcessed: v);
  static bool _message(ArtistSettings s) => s.notifyNewMessage;
  static ArtistSettings _setMessage(ArtistSettings s, bool v) =>
      s.copyWith(notifyNewMessage: v);

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
                      PortalCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            for (final toggle in _toggles)
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: toggle.get(settings),
                                onChanged: (value) =>
                                    update(toggle.set(settings, value)),
                                title: Text(toggle.label),
                              ),
                            const SizedBox(height: 4),
                            // Honest about what the switches do: they are kept on this
                            // phone (as the website keeps them in the browser) and do
                            // not yet change which emails GalleryZone sends.
                            Text(
                              'Saved on this device. They do not change which emails GalleryZone sends yet.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SecurityCard(),
                      const SizedBox(height: 16),
                      PortalCard(
                        padding: const EdgeInsets.all(16),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DeactivationTile(),
                            Divider(height: 32),
                            DeleteAccountTile(),
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

/// The Early Artist Program's free period, read from the profile: six months
/// from joining, a full year for artists who filled in the survey. Nothing is
/// billed yet - this is a dated record and a message. Port of `SubscriptionCard`.
class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard();

  static const _planName = 'Founding Artist';
  static const _renewalPriceLabel = '₹1,200/year + 18% GST (₹1,416 total)';
  static const _benefits = [
    'Unlimited artwork listings',
    '0% listing and confirmation fees',
    'Aggregator display access',
    'COA and NFC passport for every accepted piece',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(artistProfileDetailsProvider).value?.freeAccess;
    if (access == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PortalCard(
        gold: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.badgeCheck,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_planName plan',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        access.surveyRespondent
                            ? 'Free for your first year'
                            : 'Free for your first six months',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  label: access.active ? 'Active' : 'Ended',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final benefit in _benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        LucideIcons.check,
                        size: 13,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(benefit, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Text(
              access.active
                  ? 'Free until ${formatLongDate(access.until)}, then $_renewalPriceLabel. Nothing to pay until then, '
                        'and we will tell you well before anything changes.'
                  : 'Your free period ended on ${formatLongDate(access.until)}. The plan is $_renewalPriceLabel.',
              style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Changing the password. The website's card asks for the current and the new
/// password and then does nothing - there is no call behind it - so this does
/// not copy it. It does the one real thing that exists: GalleryZone emails a
/// link to the address on the account, which is how a password is set here.
class _SecurityCard extends ConsumerStatefulWidget {
  const _SecurityCard();

  @override
  ConsumerState<_SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends ConsumerState<_SecurityCard> {
  bool _busy = false;
  bool _sent = false;
  String? _error;

  Future<void> _send(String email) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(ForgotPasswordInput(email: email));
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(artistProfileDetailsProvider).value?.email ?? '';

    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            email.isEmpty
                ? 'Change your password with a link sent to your email.'
                : 'To change your password, we email a link to $email.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _busy || email.isEmpty ? null : () => _send(email),
                child: Text(
                  _busy
                      ? 'Sending…'
                      : (_sent ? 'Send it again' : 'Email me a reset link'),
                ),
              ),
              if (_sent)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 14,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Port of `features/dashboard/support-view.tsx`: how to reach GalleryZone, the
/// FAQs, and a ticket form whose tickets go to the support inbox.
class ArtistSupportScreen extends ConsumerStatefulWidget {
  const ArtistSupportScreen({super.key});

  static const path = '/dashboard/support';

  @override
  ConsumerState<ArtistSupportScreen> createState() =>
      _ArtistSupportScreenState();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ticket submitted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
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
                      Text(
                        'Contact GalleryZone',
                        style: theme.textTheme.titleMedium,
                      ),
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
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'A subject is required'
                            : null,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _message,
                        minLines: 3,
                        maxLines: 6,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter a message'
                            : null,
                        decoration: const InputDecoration(labelText: 'Message'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _isSending ? null : _submit,
                          child: Text(
                            _isSending ? 'Sending…' : 'Submit ticket',
                          ),
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
                                Text(
                                  ticket.status.name,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.message,
                              style: theme.textTheme.bodySmall,
                            ),
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
