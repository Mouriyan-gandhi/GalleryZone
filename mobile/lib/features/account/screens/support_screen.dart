import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../shell/portal_widgets.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/support-view.tsx`. Ticket submission isn't
/// wired to a live support inbox — same honest mock as the web: it records
/// the ticket locally and says so.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  static const path = '/account/support';

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _isSending = false;

  static const _faqs = <({IconData icon, String question, String answer})>[
    (
      icon: LucideIcons.fingerprint,
      question: "How do I verify an artwork's certificate?",
      answer:
          'Every artwork ships with a Certificate of Authenticity. Once delivered, '
          'open it under My Collection to see the certificate number, issue date, '
          'and NFC/QR tag status.',
    ),
    (
      icon: LucideIcons.rotateCcw,
      question: 'Can I return or cancel an order?',
      answer:
          'Orders can be cancelled before dispatch. Refunds credit to your '
          'GalleryZone wallet as store credit and apply automatically at your next '
          'checkout.',
    ),
    (
      icon: LucideIcons.repeat2,
      question: 'How does reselling my artwork work?',
      answer:
          'Any artwork in your collection can be listed for resale from the Resale '
          "page. This build covers listing and withdrawing — buyer matching isn't "
          'wired to a live marketplace yet.',
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
    setState(() => _isSending = true);
    try {
      await ref.read(customerRepositoryProvider).submitSupportTicket(
            subject: _subject.text,
            message: _message.text,
          );
      ref.invalidate(supportTicketsProvider);
      _subject.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = ref.watch(supportTicketsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact GalleryZone', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ContactLinkRow(
                        icon: LucideIcons.mail,
                        label: galleryZoneEmail,
                        url: 'mailto:$galleryZoneEmail',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Common questions', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final faq in _faqs)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    leading: Icon(faq.icon, size: 18, color: theme.colorScheme.tertiary),
                    title: Text(faq.question, style: theme.textTheme.bodyMedium),
                    children: [
                      Text(faq.answer, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                    ],
                  ),
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
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
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
                              Text(ticket.status.name, style: theme.textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(ticket.message, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Text(formatShortDate(ticket.createdAt),
                              style: theme.textTheme.labelSmall),
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
