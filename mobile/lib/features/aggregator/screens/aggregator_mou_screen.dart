import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../auth/providers/auth_providers.dart';
import '../../shell/mou_clause_view.dart';
import '../../shell/portal_widgets.dart';
import '../aggregator_mou_data.dart';
import '../providers/aggregator_providers.dart';

/// The aggregator's partner agreement with GalleryZone.
///
/// Read-and-sign, stored against [aggregatorMouVersion] so a later revision
/// asks again rather than silently inheriting an acceptance of different
/// wording. Signing is not a formality here: an unsigned aggregator has no
/// agreement covering custody, pricing or settlement, so `reserve()` refuses
/// them outright — the button below is the only way to open the portal's
/// inventory.
class AggregatorMouScreen extends ConsumerStatefulWidget {
  const AggregatorMouScreen({super.key});

  static const path = '/aggregator/mou';

  @override
  ConsumerState<AggregatorMouScreen> createState() => _AggregatorMouScreenState();
}

class _AggregatorMouScreenState extends ConsumerState<AggregatorMouScreen> {
  final _signature = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(aggregatorRepositoryProvider).acceptMou(
            signatureName: _signature.text.trim(),
            version: aggregatorMouVersion,
          );
      ref.invalidate(aggregatorProfileProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('MOU signed — you can now reserve artwork')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(aggregatorProfileProvider).value;
    final acceptance = profile?.mouAcceptance;
    final signed = acceptance != null && acceptance.version == aggregatorMouVersion;

    return Scaffold(
      appBar: AppBar(title: const Text('Aggregator MOU')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          ContentWidth(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  gold: signed,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        signed ? LucideIcons.circleCheckBig : LucideIcons.fileText,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          signed
                              ? 'Signed by ${acceptance.signatureName} on '
                                  '${formatLongDate(acceptance.acceptedAt)} '
                                  '(version $aggregatorMouVersion).'
                              : 'Version $aggregatorMouVersion. Read it through — '
                                  'signing is what lets you take custody of an '
                                  "artist's work.",
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (final paragraph in aggregatorMouPreamble) ...[
                  Text(paragraph, style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                for (final clause in aggregatorMouClauses) ...[
                  MouClauseView(clause: clause),
                  const SizedBox(height: 18),
                ],
                if (!signed) ...[
                  const SizedBox(height: 4),
                  PortalCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Declaration',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final line in aggregatorMouDeclaration)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(
                                      LucideIcons.check,
                                      size: 13,
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _signature,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Type your full name to sign',
                              helperText:
                                  'This stands as your signature on the agreement.',
                            ),
                            validator: (value) =>
                                (value ?? '').trim().isEmpty
                                    ? 'Type your full name to sign'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _submitting ? null : _sign,
                            child: Text(_submitting ? 'Signing…' : 'Sign this MOU'),
                          ),
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
