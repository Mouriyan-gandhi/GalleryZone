import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/customer.dart';
import '../../account/widgets/delete_account.dart';
import '../../auth/providers/auth_providers.dart';
import '../../legal/data/faq_data.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';

/// Port of `features/aggregator/gallery-spaces-board.tsx` - the aggregator's own
/// premises. Not the artist portal's screen of the same name, which lists an
/// artist's pieces sitting *at* an aggregator.
class AggregatorGallerySpacesScreen extends ConsumerWidget {
  const AggregatorGallerySpacesScreen({super.key});

  static const path = '/aggregator/dashboard/gallery-spaces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spaces = ref.watch(aggregatorGallerySpacesProvider);
    // Only one premises concept is modelled, so every active holding counts against it.
    final occupancy = (ref.watch(aggregatorCollectionProvider).value ?? const <AggregatorHoldingView>[])
        .where((view) => view.holding.status == HoldingStatus.reserved)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Display Spaces')),
      body: spaces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your display spaces",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorGallerySpacesProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.building2,
                title: 'No display spaces on file',
                description: 'Your display premises will appear here once registered with GalleryZone.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aggregatorGallerySpacesProvider);
                  ref.invalidate(aggregatorCollectionProvider);
                  await ref.read(aggregatorGallerySpacesProvider.future);
                },
                child: ListView(
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(LucideIcons.building2, size: 16, color: theme.colorScheme.tertiary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(space.name, style: theme.textTheme.titleMedium),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${space.addressLine1}, ${space.city}, ${space.state} ${space.pincode}',
                                                style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    PortalDetailRow(label: 'Coordinator', value: space.coordinatorName.isEmpty ? '—' : space.coordinatorName),
                                    if (space.capacity > 0) ...[
                                      PortalDetailRow(
                                        label: 'Occupancy',
                                        value: '$occupancy / ${space.capacity}',
                                        gold: occupancy >= space.capacity,
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: (occupancy / space.capacity).clamp(0.0, 1.0),
                                        minHeight: 5,
                                        backgroundColor: theme.colorScheme.outline,
                                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.tertiary),
                                      ),
                                    ] else
                                      // The API hands back no capacity for a space that never
                                      // had one set; a bar over nothing would read as full.
                                      PortalDetailRow(label: 'Occupancy', value: '$occupancy · capacity not set'),
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
      ),
    );
  }
}

/// Port of `features/aggregator/messages-inbox.tsx`. The messages are flat
/// single-message threads, not conversations, so tap-to-expand is the honest amount
/// of UI.
class AggregatorMessagesScreen extends ConsumerStatefulWidget {
  const AggregatorMessagesScreen({super.key});

  static const path = '/aggregator/dashboard/messages';

  @override
  ConsumerState<AggregatorMessagesScreen> createState() => _AggregatorMessagesScreenState();
}

class _AggregatorMessagesScreenState extends ConsumerState<AggregatorMessagesScreen> {
  String? _expandedId;

  Future<void> _toggle(MessageThread message) async {
    final opening = _expandedId != message.id;
    setState(() => _expandedId = opening ? message.id : null);
    if (!opening || !message.unread) return;
    final container = ProviderScope.containerOf(context);
    try {
      await ref.read(aggregatorRepositoryProvider).markMessageRead(message.id);
      container.invalidate(aggregatorMessagesProvider);
    } catch (_) {
      // Reading it worked; only the "read" mark didn't stick, and it will be asked
      // again the next time it is opened.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(aggregatorMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: messages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your messages",
          description: authErrorMessage(error),
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorMessagesProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.mail,
                title: 'No messages',
                description: 'Updates from GalleryZone about assignments, audits, and settlements will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aggregatorMessagesProvider);
                  await ref.read(aggregatorMessagesProvider.future);
                },
                child: ListView(
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
                                    InkWell(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      onTap: () => _toggle(message),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Icon(
                                                message.unread ? LucideIcons.mail : LucideIcons.mailOpen,
                                                size: 17,
                                                color: message.unread ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          message.subject,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.textTheme.bodyMedium?.copyWith(
                                                            fontWeight: message.unread ? FontWeight.w600 : FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(formatDay(message.receivedAt), style: theme.textTheme.labelSmall),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${message.from} · ${message.preview}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: theme.textTheme.labelSmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Icon(
                                                _expandedId == message.id ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                                size: 16,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_expandedId == message.id)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(43, 0, 14, 16),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(message.body, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
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
    final settingsAsync = ref.watch(aggregatorSettingsProvider);
    final settings = settingsAsync.value;

    Future<void> update(AggregatorSettings next) async {
      final container = ProviderScope.containerOf(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(aggregatorRepositoryProvider).updateSettings(next);
        container.invalidate(aggregatorSettingsProvider);
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }

    if (settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: settingsAsync.hasError
            ? EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't load your settings",
                description: authErrorMessage(settingsAsync.error!),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(aggregatorSettingsProvider),
                  child: const Text('Try again'),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
                  onChanged: (value) => update(settings.copyWith(notifyNewAssignment: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sale recorded'),
                  value: settings.notifySaleRecorded,
                  onChanged: (value) => update(settings.copyWith(notifySaleRecorded: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Settlement processed'),
                  value: settings.notifySettlementProcessed,
                  onChanged: (value) => update(settings.copyWith(notifySettlementProcessed: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('30-day display window expiring soon'),
                  value: settings.notifyExpiryReminder,
                  onChanged: (value) => update(settings.copyWith(notifyExpiryReminder: value)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Push delivery is not wired up in this build — these only record your preference.',
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

/// Port of `features/aggregator/support-view.tsx`: the ways to reach GalleryZone,
/// the aggregator FAQ, a ticket form and the tickets so far. Tickets go to the live
/// support inbox, as on the artist's Support page.
class AggregatorSupportScreen extends ConsumerStatefulWidget {
  const AggregatorSupportScreen({super.key});

  static const path = '/aggregator/dashboard/support';

  @override
  ConsumerState<AggregatorSupportScreen> createState() => _AggregatorSupportScreenState();
}

class _AggregatorSupportScreenState extends ConsumerState<AggregatorSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(aggregatorRepositoryProvider).submitSupportTicket(
            subject: _subject.text,
            message: _message.text,
          );
      container.invalidate(aggregatorSupportTicketsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Ticket submitted.')));
      if (mounted) {
        _subject.clear();
        _message.clear();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = ref.watch(aggregatorSupportTicketsProvider).value ?? const <SupportTicket>[];

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
                const SupportFaqPanel(audience: FaqAudience.aggregators),
                const SizedBox(height: 24),
                Text('Raise a ticket', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _subject,
                        enabled: !_sending,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'e.g. Question about my advance payment',
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty ? 'A subject is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _message,
                        enabled: !_sending,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Describe your issue...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a message' : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _sending ? null : _submit,
                          child: Text(_sending ? 'Sending…' : 'Submit ticket'),
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
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _TicketStatusPill(status: ticket.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(ticket.message, style: theme.textTheme.labelSmall?.copyWith(height: 1.45)),
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
      SupportTicketStatus.open => StatusPill(label: 'Open', color: theme.colorScheme.tertiary),
      SupportTicketStatus.answered => const StatusPill(label: 'Answered', color: Color(0xFF34D399)),
      SupportTicketStatus.closed => StatusPill(label: 'Closed', color: theme.colorScheme.outline),
    };
  }
}
